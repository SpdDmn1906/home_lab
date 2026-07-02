# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A production-shaped home datacenter managed as code. There is **no application to build or test** — the repo is OpenTofu/Terraform HCL, Ansible playbooks, Docker Compose files, monitoring configs, and a large suite of operational Bash scripts. Most commands here mutate real infrastructure on the media host, so default to read-only/plan operations and confirm before applying.

`GEMINI.md` is a parallel AI-context file with overlapping content; keep it roughly in sync when you change operational facts here.

## Operating model (read first)

- The infra tools (`tofu`/`terraform`, `ansible`, `docker`, `kubectl`) are **not assumed to be installed in the editing environment**. The repo is authored in the workspace and applied against the **media host `mediaserver` (192.168.1.11)**, which owns the Docker socket, GPU, and host networking. Don't assume a command that applies state can run from wherever you're editing.
- **Do not manually edit running containers or host configs.** All changes go through Terraform/Ansible so state stays consistent (see `GEMINI.md` "Infrastructure Changes").
- **Phase ordering is strict and is the project's governing constraint.** Production-stability work (failing disk, single-node DNS) outranks every career/portfolio item. Read `docs/roadmap/INFRASTRUCTURE_HARDENING_ROADMAP.md` before proposing new work; current focus is **Phase 5a (K3s sidecar cluster bring-up)**.

## Common commands

Primary entry point (Terraform + Ansible lifecycle):
```bash
./scripts/root_utils/infrastructure-manager.sh init     # terraform init + ensure ansible inventory
./scripts/root_utils/infrastructure-manager.sh plan     # terraform plan -> tfplan
./scripts/root_utils/infrastructure-manager.sh deploy   # terraform apply tfplan + ansible-playbook + verify
./scripts/root_utils/infrastructure-manager.sh verify   # health checks (docker ps + endpoint probes)
./scripts/root_utils/infrastructure-manager.sh status   # terraform state list + docker + network + disk
./scripts/root_utils/infrastructure-manager.sh destroy  # CAUTION: prompts "DESTROY", backs up first
```

Working directly with the IaC (run from repo root):
```bash
cd terraform && tofu init && tofu plan && tofu apply    # tofu is canonical; terraform still works (compatible state)
tofu fmt -recursive && tofu validate                    # there is no test suite — use these to verify HCL
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/infrastructure-setup.yml --syntax-check
docker compose -f docker/docker-compose.yml up -d        # monitoring stack + Plex (host networking)
```

Operational scripts (verification before mutation):
```bash
./scripts/health-checks/system-health.sh
./scripts/diagnostics/comprehensive_network_test.sh
./scripts/adaptive_corruption_scan.sh                    # FFmpeg-based, multi-phase, parallelized
```

## Known footguns (verified, not theoretical)

- **`tofu` vs `terraform` naming drift.** README and `terraform/main.tf` declare OpenTofu (`tofu`) canonical as of 2026-06-09, but `infrastructure-manager.sh`'s prerequisite check and commands still call the `terraform` binary. State is binary-compatible, so both work, but the wrapper hasn't been updated.
- **Ansible deploy stage is partial.** `ansible/playbooks/infrastructure-setup.yml` `include_tasks: tasks/*.yml` for many steps, but no `ansible/playbooks/tasks/` directory exists in the repo (only `vars/`). The playbook will fail those includes until those task files are added.
- **`docker/docker-compose.yml` hardcodes `GF_SECURITY_ADMIN_PASSWORD=admin`** — change Grafana creds on first login; never leave at `admin/admin`.

## Architecture

### Terraform (`terraform/`)
Root `main.tf` manages **Docker resources on the media host** via the `kreuzwerker/docker` provider (`unix:///var/run/docker.sock`), with `backend "local"` (state in `terraform/terraform.tfstate`). Consumer-router config (VLAN/DHCP) is deliberately **not** in Terraform — it lives in docs/Ansible because it needs vendor APIs.

Modules exist on disk (`adguard`, `parental-controls`, `remote-access`, `ai-assistant`, `network`, `docker`, `starr`) but **only `docker_services` and `starr` are wired into `main.tf`** — the rest are commented out. AdGuard runs from `docker/adguard/docker-compose.yml` instead of its module.

### STARR stack — VPN gateway pattern (`terraform/modules/starr/`)
This is the most intricate piece. A single **`binhex/arch-qbittorrentvpn`** container (PIA WireGuard, `privileged`) acts as the network gateway; **all other STARR apps (Radarr, Sonarr, Prowlarr, FlareSolverr, Bazarr) share its network namespace**, so every STARR port is published on that one container. This replaced the older Gluetun + qBittorrent split (`main.tf.gluetun_backup` is the legacy version). Practical implication: STARR connectivity problems almost always trace back to the VPN container's health, not the individual apps. `docker/starr/docker-compose.yml.recommended` is a reference snapshot — Terraform is the canonical deployer.

### Monitoring (`docker/docker-compose.yml` + `monitoring/`)
Prometheus + Grafana + Alertmanager + Loki/Promtail, plus exporters (node, cAdvisor, plex, speedtest, blackbox). Plex runs `network_mode: host` with `/dev/dri` passthrough for Intel Quick Sync transcoding. Config files in `monitoring/` are bind-mounted read-only into the containers.

### Fortress mode (offline operation) — `scripts/fortress/`
Lets the household work during WAN outages. `plex-fortress-guard.sh` runs via systemd timer (`.service` + `.timer` in the same dir) and blocks `plex.tv` to force Plex to use cached auth; Plex `allowedNetworks` must be `192.168.1.0/24` and local DNS (AdGuard/Unbound) must be primary. The strategic goal is to generalize this from Plex to the whole stack ("Internet-Optional Household").

### Scripts (`scripts/`)
~100 Bash scripts; assume `set -euo pipefail`. Organized subdirs (`health-checks/`, `diagnostics/`, `fixes/`, `backup/`, `maintenance/`, `fortress/`, `monitoring/`, `root_utils/`) hold the durable tooling. The many top-level `*_scan.sh` / `*_corruption_*` / `*_duplicate_*` / `*_quarantine_*` files are the FFmpeg-based **media-integrity suite** (parallelized corruption + duplicate detection) — largely task-specific one-offs; prefer reusing/extending the subdir scripts over the flat ones.

## Adding the next roadmap coding tasks

Source of truth is `docs/roadmap/INFRASTRUCTURE_HARDENING_ROADMAP.md` — read the "Active Build Priorities" block first and respect the gate: **nothing in Phase 5 starts until Phase 2 (failing disk) and Phase 3 (DNS isolation) land.** Where each near-term coding workstream's code goes and how to verify it:

### Add a Terraform-managed service (e.g. Phase 4 self-hosted Gitea)
Follow `terraform/modules/starr/` as the template — this is the repo's extension pattern:
1. Create `terraform/modules/<name>/{main.tf,variables.tf,outputs.tf}`.
2. Add `enable_<name>` to the `features` object in `terraform/variables.tf` (type + `default`).
3. Wire it into `terraform/main.tf`: `module "<name>" { count = var.features.enable_<name> ? 1 : 0; source = "./modules/<name>"; ... }` — the commented-out `adguard`/`ai_assistant`/`remote_access` blocks show the exact shape. Add an `output` if it should surface in `tofu output`.
4. Verify: `cd terraform && tofu fmt -recursive && tofu validate && tofu plan` — the plan must show **only** the new resources, nothing else changed.

### Phase 4 Ansible roles (CIFS auto-heal, bare-metal → running-lab)
`ansible/roles/` does **not exist yet**, and `infrastructure-setup.yml` references `include_tasks: tasks/*.yml` files that aren't in the repo — building the roles is also what fixes that partial-deploy footgun.
1. Create `ansible/roles/<role>/{tasks,handlers,defaults,templates}/main.yml`. Roadmap-named roles: `cifs_mount`, `docker_host`, `plex_gpu`, `adguard`, `starr_stack`, `fortress_guard`, `monitoring_stack`.
2. Add `ansible/playbooks/site.yml` that composes the roles; replace the placeholder `include_tasks` with role calls.
3. Verify: `--syntax-check`, then `--check` (dry run) before any live run.
4. Acceptance (roadmap): fresh Ubuntu VM → `ansible-playbook site.yml` → Plex serves a movie in <10 min.

### Phase 4 Alerts-as-Code
Add alert groups to `monitoring/prometheus/rules.yml` (already covers system/network/service/storage/temperature/uptime). Still missing per roadmap: **CIFS-mount-lost**, **`plex_fortress_guard_state != 0` for >1h** (requires the fortress guard to first export that metric via a node-exporter textfile collector — a coding dependency, not just a rule), and **container-restart-rate**. Verify with `promtool check rules monitoring/prometheus/rules.yml`, then reload (`curl -X POST http://localhost:9090/-/reload`).

### Phase 5c `infra-mcp` — flagship, NEW standalone codebase
No home in the repo yet, and it is **not** wired into Terraform/Ansible — it's a standalone Python project.
1. Create `infra-mcp/` (own `pyproject.toml`/venv) on the official `mcp` SDK, **local stdio** transport, **read-only tools only** in v1.
2. One provider module per service: `homelab` (Prometheus/Alertmanager + the Sonarr/Radarr/Plex/fortress operations bash is bad at), `aws` (Cost Explorer + light describe/list), `linode` (stream-up + instance metrics). Reach internal services over Tailscale; call APIs/existing bash rather than reimplementing them.
3. Secrets in a gitignored `.env` (`.gitignore` already covers `*.env`): scoped read-only AWS principal, read-only Linode token, Tailscale-internal Prometheus URL.
4. Headline tool: `estate.health_overview`. Verify each tool returns read-only data via the MCP inspector or by registering the server in the Claude Desktop/Code MCP config.
5. Right-sizing guard: keep it read-only and personal; action tools and hosted always-on are deliberately deferred — don't add them speculatively.

### K3s workloads & Phase 5h delivery — mostly NOT in this repo
- K3s/GitOps manifests (Phase 5a/5b/5e/5f) live in a **separate `home_lab_k3s/` repo**, not here; cluster bring-up is `docs/guides/OPENTOFU_K3S_MIGRATION.md` Part 2. Hard boundary: never move Plex/STARR/AdGuard/fortress/monitoring off Docker.
- Phase 5h: `janellechung-site` deploy automation (Terraform + GitHub Actions) belongs in that site's repo; only the **Linode stream monitoring** piece lands here — add a scrape target + blackbox probe and alert rules under `monitoring/`.

### AdGuard query-log analyzer (Python observability utility — `scripts/monitoring/`)
Small stdlib-Python CLI that parses AdGuard Home's `querylog.json` (JSON-per-line) into **top-N domains/clients** + blocked-vs-allowed rate (`json` + `collections.Counter`/`defaultdict` + `argparse`). ⚠️ The query log is household browsing data — keep raw logs/output **out of git**; commit only the generic script (fake-domain sample data if any).

## Secrets & config

Everything sensitive is gitignored — never commit it. Create from the templates before deploying:
- `env.template` → `.env`
- `config/mediaserver.env.example` → host-specific overrides in `config/`
- `terraform/terraform.tfvars.example` → `terraform/terraform.tfvars`
- Ansible expects `ansible/playbooks/vars/secrets.yml` (referenced by the playbook, gitignored)

`.gitignore` also excludes `*.tfstate`, `.terraform/`, `*.env`, `*.key/*.pem/*.crt`, and `secrets/`.

## Network constants (recur everywhere)

- Subnet `192.168.1.0/24` (unified, double-NAT eliminated) · Gateway `192.168.1.1` (Asus router)
- Media host `mediaserver` `192.168.1.11` (Docker host) · Synology NAS `192.168.1.20`
- Service ports: Grafana 3000, Prometheus 9090, Alertmanager 9093, Plex 32400, qBittorrent 8080
