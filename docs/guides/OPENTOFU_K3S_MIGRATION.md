# OpenTofu Migration + K3s Bring-up Runbook

**Owner**: Stephen Chung
**Date**: 2026-06-09
**Status**: ACTIVE — execute in two passes (OpenTofu first, K3s second)
**Repo**: `home_lab`
**Related**: `docs/roadmap/INFRASTRUCTURE_HARDENING_ROADMAP.md` Phase 5a, `terraform/main.tf`

---

## WHY THIS MATTERS

Two unrelated upgrades to the home lab platform that happen to land in the same window:

1. **OpenTofu** is the Linux Foundation fork of Terraform that landed after HashiCorp's August 2023 BSL license change. It's drop-in compatible with Terraform 1.5.x state and HCL syntax, MPL-2.0 licensed, community-governed. Moving the home lab off Terraform onto OpenTofu costs ~30 minutes and gives the repo OSS-license clarity plus a credible interview talking point about staying current with the IaC ecosystem.
2. **K3s** is the lightweight Kubernetes distro for the Phase 5a sidecar cluster — a separate node where experimental workloads (LLM inference, n8n, Vaultwarden, etc.) can run with real K8s patterns without putting Plex or the STARR stack at risk. Phase 5a in the roadmap has been scoped for months; this is the runbook that takes it from "planned" to "running."

The two are bundled in one runbook because they share a deployment session and verification window. OpenTofu first (lower-risk tooling swap on the existing media host), then K3s on the new node. Failing the first half does not block the second.

## PROS / CONS

**OpenTofu**
- Pros: Free, OSS-aligned, identical HCL syntax, identical provider ecosystem, binary-compatible state up to TF 1.5.5, faster release cadence with early-mover features (state encryption, provider iteration, early eval), portfolio differentiator for OSS-leaning hiring managers.
- Cons: Migration breaks Terraform Cloud / HCP Terraform integration (not used here, so N/A). Some third-party tooling (Atlantis, tfsec, infracost) needed a beat to add `tofu` support but is caught up now. Newer than Terraform so smaller community in absolute terms.

**K3s**
- Pros: Single binary <100 MB, low memory footprint (suitable for Pi 4/5 or a small mini-PC), embedded SQLite for control plane (no separate etcd), CNCF-certified, full Kubernetes API. Real K8s patterns (manifests, RBAC, ingress, sealed secrets) for portfolio without the operational weight of full K8s.
- Cons: Adds a node and a maintenance surface. Networking debugging is harder than Docker Compose. Some Plex/STARR-specific features (host networking, GPU passthrough, host iptables hooks) actively fight K8s — the strict rule is **NEVER migrate the prod media stack here**. Sidecar cluster only.

---

## CONTEXT

The existing IaC layer in `terraform/` manages Docker containers on `mediaserver` via the `kreuzwerker/docker` provider, with `terraform/modules/{adguard,docker,starr,...}` covering each workload group. State lives in `terraform/terraform.tfstate` (local backend). No remote state, no CI runner — `terraform apply` runs from the developer laptop or directly on the host.

The K3s cluster is **not** going to take over any of this. The Docker layer and OpenTofu management of it stays exactly as-is. K3s lives on a separate node and hosts experimental workloads only.

---

## PART 1: OPENTOFU MIGRATION

### 1.1 Prerequisites

- Current Terraform version: `terraform version` (record it; if it is `>= 1.5.6` you cannot binary-import the state file directly, you must `tofu init -migrate-state`).
- Working `terraform apply` baseline: run `terraform plan` and confirm **zero changes**. If the plan is dirty, fix that first — never start a tooling migration with drift.
- A backup of the state file (next step).

### 1.2 Backup state file (safety net)

```bash
cd terraform/
cp terraform.tfstate "terraform.tfstate.pre-tofu-$(date +%Y%m%d-%H%M%S)"
cp terraform.tfstate.backup "terraform.tfstate.backup.pre-tofu-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
ls -la terraform.tfstate*
```

The point of the timestamped copies is that if anything goes sideways during `tofu init -migrate-state` you can restore byte-for-byte and re-run `terraform plan` to confirm the world is back to its pre-migration baseline.

### 1.3 Install OpenTofu

```bash
brew install opentofu
tofu version
```

Expected: `OpenTofu v1.10.x` or later. The version line should mention `+ provider source registry`.

### 1.4 Provider compatibility check

The repo uses three providers (`kreuzwerker/docker`, `hashicorp/local`, `hashicorp/null`). All three publish to the OpenTofu registry mirror automatically — no provider-source rewrites required. The existing `required_providers` block in `main.tf` works unchanged.

If at some point you adopt a HashiCorp-published provider that is BSL-licensed and OpenTofu cannot redistribute it, OpenTofu falls back to fetching it from the upstream HashiCorp registry. So far this has not bitten anyone in practice.

### 1.5 Initialize OpenTofu against existing state

```bash
cd terraform/
tofu init -migrate-state
```

Watch the output for these signals:

- `Initializing the backend...` — backend block is read.
- `Migrating state from previous state file...` — state copy is in-flight.
- `Terraform has been successfully initialized!` — yes, OpenTofu still prints "Terraform" in some messages; this is cosmetic, the actual binary is `tofu`.
- `Initialization complete!` — done.

If the migration prompts to confirm anything, read carefully before answering `yes`. The expected prompts are about creating a new lock file and confirming the backend type, not about destroying or replacing resources.

### 1.6 Verify plan is still zero-change

```bash
tofu plan
```

Required output: `No changes. Your infrastructure matches the configuration.`

If you see proposed changes that you did NOT introduce yourself in the same session, **stop**. Restore the state backup from step 1.2 and investigate before touching anything. Common cause: provider version drift between what Terraform last resolved and what OpenTofu just re-resolved. Pin provider versions in `required_providers` if needed.

### 1.7 Verify a no-op apply

```bash
tofu apply
```

Expected: `Apply complete! Resources: 0 added, 0 changed, 0 destroyed.`

If anything other than zero, restore the backup and investigate.

### 1.8 Update the wrapper script

`scripts/root_utils/infrastructure-manager.sh` (per README) wraps `terraform` commands. Either:

- Replace the binary name from `terraform` to `tofu` in the script directly, OR
- Add a shell alias `alias terraform=tofu` and leave the script alone. Works but less honest about what's actually installed.

The script-edit path is preferred — it makes the OpenTofu adoption visible in the repo diff.

```bash
sed -i.bak 's/\bterraform\b/tofu/g' scripts/root_utils/infrastructure-manager.sh
diff scripts/root_utils/infrastructure-manager.sh.bak scripts/root_utils/infrastructure-manager.sh
```

Review the diff before deleting the `.bak`.

### 1.9 Drop the Terraform binary (optional)

```bash
brew uninstall terraform  # optional, only after confirming tofu works for a week+
```

Keeping both installed is fine and is the safer move during the burn-in week.

### 1.10 OpenTofu rollback procedure

If you decide to revert (no shame in it):

```bash
cp terraform.tfstate.pre-tofu-YYYYMMDD-HHMMSS terraform.tfstate
sed -i.bak 's/\btofu\b/terraform/g' scripts/root_utils/infrastructure-manager.sh
terraform init
terraform plan  # confirm zero changes
```

OpenTofu writes state in the same binary format Terraform reads, so the rollback is symmetric.

---

## PART 2: K3S BRING-UP

### 2.1 Prerequisites

- A second node. Phase 5a in the roadmap names a Pi 5 (after Phase 3 DNS isolation is complete) or a separate mini-PC. **Do not** install K3s on `mediaserver` — that violates the "experimental workloads cannot touch Plex" rule.
- Static IP on the new node (assigned via router DHCP reservation). Document it in `docs/architecture/network-setup.md`.
- SSH access from `mediaserver` to the new node via Tailscale or local LAN.
- The node should be running Ubuntu 24.04 LTS or Debian 12 minimum. K3s supports both equally; Ubuntu is closer to existing host parity.

### 2.2 OS prep on the K3s node

```bash
ssh sc-k3s-01
sudo apt update && sudo apt -y upgrade
sudo apt -y install curl jq htop net-tools
sudo timedatectl set-timezone America/New_York  # match the rest of the lab
sudo hostnamectl set-hostname sc-k3s-01
```

If using a Raspberry Pi, also:

```bash
sudo sed -i 's/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/cmdline.txt
sudo reboot
```

K3s needs cgroup memory accounting on; Pi OS does not enable it by default.

### 2.3 Install K3s (single-node, server mode)

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb --write-kubeconfig-mode 644" sh -
```

Flag breakdown:
- `--disable traefik` — we want nginx-ingress instead. Traefik works fine but the home lab already uses nginx patterns in other configs.
- `--disable servicelb` — opinionated choice, NOT necessity. ServiceLB is K3s's built-in load balancer; it works fine for home-lab use and is genuinely the easier path for first-pass smoke tests (no nginx-ingress to wire up before you can hit a service). The reason this runbook disables it: we want to use nginx-ingress + Tailscale Funnel for the ingress story (more aligned with what you'll do in production roles). **If you'd rather take the easier path and skip nginx-ingress until later, drop `--disable servicelb` from the install command.** Both approaches lead to working clusters; the choice is about which ingress pattern you want to learn.
- `--write-kubeconfig-mode 644` — makes `/etc/rancher/k3s/k3s.yaml` readable by non-root, simplifies kubectl from the dev laptop.

Verify:

```bash
sudo systemctl status k3s
sudo k3s kubectl get nodes
```

Expected: one node, `Ready`, role `control-plane,master`.

### 2.4 kubectl from the dev laptop

```bash
mkdir -p ~/.kube
scp sc-k3s-01:/etc/rancher/k3s/k3s.yaml ~/.kube/sc-k3s-01-config
sed -i.bak 's/127.0.0.1/<node-tailscale-or-lan-IP>/' ~/.kube/sc-k3s-01-config
export KUBECONFIG=~/.kube/sc-k3s-01-config
kubectl get nodes
```

Add the export to `~/.zshrc` if this becomes your default cluster.

### 2.5 Install nginx-ingress

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl get pods -n ingress-nginx
```

For a home lab on Tailscale, the `LoadBalancer` service type that ingress-nginx creates will sit in `<pending>` forever (no cloud LB exists). That's fine — Tailscale Funnel or a `NodePort` service exposure handles ingress without a real LB. Document the chosen pattern in `docs/guides/k3s-ingress.md` when you adopt it.

### 2.6 First workload (smoke test)

Deploy something throwaway to confirm the cluster can schedule, expose, and serve:

```bash
kubectl create deployment hello --image=nginxdemos/hello --port=80
kubectl expose deployment hello --port=80 --type=NodePort
kubectl get svc hello
```

Hit the NodePort URL from a browser; it should return the nginx demo page.

```bash
kubectl delete deployment hello
kubectl delete svc hello
```

### 2.7 What runs here vs what doesn't

Per Phase 5a's hard boundary, the prod media stack stays on Docker Compose on `mediaserver`. K3s is for:

- LLM inference (Ollama, vLLM)
- n8n / workflow automation experiments
- Vaultwarden / Bitwarden self-host
- Sealed Secrets demo
- ArgoCD (Phase 5b)
- Throwaway dev workloads

Hard NO on this cluster:
- Plex, the STARR stack, qBittorrent, AdGuard (host networking + GPU + iptables requirements)
- Anything that the family relies on day-to-day
- Anything stateful without a tested backup story for K3s SQLite

### 2.8 K3s rollback procedure

Single-node K3s comes with its own uninstaller:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

That removes the binary, the systemd unit, the data directory, and the kubeconfig. Pi OS or Ubuntu is restored to a state that looks like K3s was never installed. The node can be reformatted entirely if needed.

---

## VERIFICATION CHECKLIST

After both halves complete:

- [ ] `tofu plan` on the media host returns "No changes"
- [ ] `tofu apply` on the media host returns "0 added, 0 changed, 0 destroyed"
- [ ] `infrastructure-manager.sh` wrapper uses `tofu`, not `terraform`
- [ ] All Plex / STARR / AdGuard / fortress containers running and healthy (`docker ps` + Grafana dashboards)
- [ ] K3s node shows `Ready` via `kubectl get nodes`
- [ ] Smoke-test workload deployed and deleted successfully
- [ ] nginx-ingress controller pods `Running`
- [ ] `docs/architecture/network-setup.md` updated with the K3s node IP
- [ ] Roadmap Phase 5a checkbox flipped to in-progress

---

## RESUME / PORTFOLIO FRAMING

Once both halves are in, the talking points:

- "Migrated personal IaC layer from Terraform to OpenTofu after the HashiCorp BSL license change to maintain OSS license clarity. Documented the migration as a reusable runbook."
- "Stood up a single-node K3s sidecar cluster for experimental workloads while keeping the production media stack on Docker Compose — chose hybrid architecture deliberately rather than full K8s migration because Plex's host networking and GPU passthrough requirements fight K8s. Wrote up the trade-off analysis."
- "Both moves were execution against a pre-existing Phase 5 roadmap in the home_lab repo — demonstrates ability to scope work over months, defer to stability priorities (Phase 2 hardware fix outranks Phase 5 career-growth work), and ship the deferred items when their prerequisites land."

The second talking point — the deliberate hybrid architecture — is the more interesting one in an interview. It shows that the choice not to use K8s for a workload is as informed as the choice to use it.

---

## DEPENDENCIES

- OpenTofu (Homebrew tap or direct binary install)
- K3s (curl install script, no package manager needed)
- A second node (Pi 5, mini-PC, or NUC — Phase 5a roadmap-aligned)
- Tailscale (for cross-node access; already installed per existing lab setup)
- nginx-ingress-controller manifest from upstream
- kubectl on the dev laptop (`brew install kubectl`)
- Optional: k9s for terminal-friendly cluster browsing (`brew install k9s`)

---

## WHAT THIS RUNBOOK DOES NOT COVER

- ArgoCD installation on the K3s cluster — Phase 5b, separate runbook when it's time.
- Multi-node K3s (HA control plane) — single-node is intentional for the sidecar cluster; HA is overkill at home-lab scale.
- Migrating any Plex / STARR / AdGuard workload to K3s — see Phase 5a hard boundary above. Don't.
- Production state-encryption with OpenTofu (a 1.7+ feature) — local state on a personal laptop does not need it; revisit if remote state ever lands.
- CI runner integration (`tofu` in GitHub Actions) — there is no CI runner yet; revisit when one exists.
