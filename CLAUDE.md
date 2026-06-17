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
