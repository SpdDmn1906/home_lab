# Home Lab

A production-shaped personal infrastructure I use to run the household stack and to learn platform-engineering patterns I'd otherwise only touch at work. Built by [Stephen Chung](https://linkedin.com/in/stephenachung) — DevOps / DevSecOps engineer, currently sole DevOps operator at a B2B cannabis-marketing SaaS.

The lab serves three audiences: my family (Plex / DNS / cameras), my own career growth (deliberate platform projects that produce portfolio artifacts), and curious hiring managers who want to see how I make architectural decisions in a low-stakes environment.

## Current Focus (2026-06)

- **ACTIVE — Phase 5a**: K3s sidecar cluster bring-up. See [`docs/guides/OPENTOFU_K3S_MIGRATION.md`](docs/guides/OPENTOFU_K3S_MIGRATION.md).
- **JUST COMMITTED**: Phase 5e (Paperless-ngx) + Phase 5f (Immich) + Phase 5g (Frigate on Coral TPU) + Phase 5c reframed around a custom MCP server for home lab APIs.
- **STRATEGY DOC**: ["Local-AI Portfolio Strategy"](docs/roadmap/INFRASTRUCTURE_HARDENING_ROADMAP.md#-local-ai-portfolio-strategy-2026-06-10) at the bottom of the roadmap — explains the through-line connecting Phase 5/6 to my edge-AI-deployment career narrative.

## Engineering decisions worth calling out

- **Hybrid Docker + K3s, not full Kubernetes migration.** Plex, the STARR stack, AdGuard, and the fortress guard stay on Docker on the media host because they need host networking, GPU passthrough, and host iptables hooks that fight K8s. The K3s sidecar cluster (Phase 5a) is for experimental workloads only. The deliberate choice not to migrate prod is the more interesting decision than the migration itself.
- **OpenTofu over Terraform (2026-06-09).** Binary-compatible state, identical HCL, OSS-licensed. Migration runbook in `docs/guides/`.
- **Two-stage rollouts on every AI-touching project.** Phase 5e and 5f each ship Stage 1 vanilla (CPU, no AI) before Stage 2 GPU-backed ML. Avoids the failure mode of forcing a CPU build that nobody uses.
- **MCP server over custom CLI** (Phase 5c). Model Context Protocol is what Claude Code, Cursor, LM Studio, and Hermes Agent already consume. One implementation, many consumers — stronger differentiator in 2026 than yet-another-Go-CLI.
- **Phase ordering is strict.** Failing disk (Phase 2) and single-node DNS dependency (Phase 3) outrank every career-growth item. Production stability beats resume polish — explicit anti-goal at the top of the roadmap.

## Tech surface

- **IaC**: OpenTofu (migrated from Terraform), Ansible
- **Container / orchestration**: Docker Compose on the media host, K3s for the experimental cluster
- **GitOps (planned, Phase 5b)**: leaning FluxCD over ArgoCD for the OpenTofu-bootstrap fit and Renovate-bot pairing
- **Observability**: Prometheus + Grafana + Loki + Promtail (default Grafana credentials must be changed on first login — do not leave at `admin/admin`)
- **Networking**: Tailscale mesh, Unbound DNS via AdGuard Home (Phase 3 isolates this onto a Pi)
- **Local AI (Phase 5e/5f/5g)**: Ollama, candidate Hermes Agent runtime, Coral TPU edge inference
- **Storage**: Synology NAS (CIFS-mounted), local SSD for hot data

## Architecture detail

(The consumer-grade router details below describe my actual network. They're not the interesting part of the repo — `docs/architecture/architecture.md` is the load-bearing detail document.)

### Network topology
- **Internet**: Comcast Xfinity 2GB with Xfinity Xfi modem (bridge mode)
- **Routers**: Asus Nighthawk RAX50 (primary), Amazon Eero (mesh extension, 3 nodes in bridge mode)
- **Unified subnet**: 192.168.1.0/24 (eliminated double NAT)
- **VLAN segmentation**: deferred to Phase 6 Theme C when router refresh happens

### Compute and storage
- **Media host (`mediaserver`)**: main desktop, Docker containers — Plex, STARR stack, AdGuard, fortress guard, monitoring
- **NAS**: Synology 2-bay, 4TB (TV / movies / future Paperless-ngx and Immich storage)
- **External HDD**: 2TB (legacy media)
- **Future nodes** (target hardware footprint in the roadmap): K3s / dev node, Pi DNS/HA control node, AI / intelligence GPU node, Frigate / edge-inference node, self-hosted Git node

## 📁 Project Structure

```
home_lab/
├── docs/                            # Documentation Center
│   ├── roadmap/                     # ★ Roadmaps & purchasing (START HERE for direction)
│   │   ├── INFRASTRUCTURE_HARDENING_ROADMAP.md   # Phased execution plan (incl. Phase 6 vision)
│   │   ├── HARDWARE_ROADMAP.md                    # Unified purchasing sequence
│   │   └── ups-deep-dive.md                       # Phase 4 UPS sizing + NUT setup
│   ├── architecture/                # High-level design & target topology
│   ├── guides/                      # How-to guides & setup instructions
│   ├── troubleshooting/             # Fixes for common issues
│   ├── reports/                     # Deep-dive analysis & audits
│   └── archive/                     # Historical logs & session summaries
├── docker/                          # Docker Compose configurations
├── terraform/                       # Infrastructure as Code (Terraform)
├── ansible/                         # Configuration Management (Ansible)
├── scripts/                         # Automation & Utility Scripts
│   ├── fortress/                    # Plex fortress guard (iptables watchdog)
│   ├── health-checks/               # Health monitoring
│   ├── diagnostics/                 # System & network checks
│   ├── fixes/                       # Auto-fix scripts
│   ├── backup/                      # Backup automation
│   ├── maintenance/                 # Routine maintenance
│   └── log-error-scanner.sh         # Container log error textfile collector
├── monitoring/                      # Prometheus/Grafana configs
└── README.md                        # This file
```

## 🌅 Direction & Roadmap

**Guiding principle**: Internet-Optional Household — fortress mode generalized from Plex to the whole family.

- 📍 **[Infrastructure Hardening Roadmap](docs/roadmap/INFRASTRUCTURE_HARDENING_ROADMAP.md)** — phased execution plan from emergency stabilization through 2-5 year vision.
- 🛒 **[Hardware Roadmap](docs/roadmap/HARDWARE_ROADMAP.md)** — single source of truth for all hardware purchases, sequenced against the roadmap phases.
- 🏗️ **[Architecture](docs/architecture/architecture.md)** — current state, target multi-node topology, and the SPOFs each phase eliminates.

## 🚀 Quick Start

### Option 1: Automated Infrastructure Setup (Recommended)
```bash
# Complete infrastructure management with Terraform + Ansible
./scripts/root_utils/infrastructure-manager.sh init    # Initialize infrastructure
./scripts/root_utils/infrastructure-manager.sh deploy  # Deploy everything
```

### Option 2: Quick Setup (15 minutes)
```bash
cat docs/guides/quick-start.md
```

## 📚 Documentation Reference

### 📘 Setup & Guides (`docs/guides/`)
- [STARR Stack Deployment](docs/guides/starr-deployment.md) - **Complete Terraform Deployment Guide**
- [Bazarr Setup](docs/guides/bazarr-setup.md) - Automated subtitles for Sonarr/Radarr (Plex)
- [Quick Start Guide](docs/guides/quick-start.md) - Fast track setup
- [DNS Setup](docs/guides/dns-setup.md) - Name resolution & Static IPs
- [AdGuard Home Setup](docs/guides/adguard-setup.md) - Ad blocking & Unbound DNS
- [Infrastructure Management](docs/guides/infrastructure-management.md) - IaC Guide
- [Network Unification Checklist](docs/guides/network-unification-checklist.md) - Network migration guide
- [OpenTofu + K3s Migration](docs/guides/OPENTOFU_K3S_MIGRATION.md) - Terraform→OpenTofu swap + K3s sidecar cluster bring-up (Phase 5a)

### 🔧 Troubleshooting (`docs/troubleshooting/`)
- [CIFS Storage Fixes](docs/troubleshooting/NETWORK_SERVICE_AND_CIFS_FIXES.md) - Fix mount errors & permissions
- [STARR App Connectivity](docs/troubleshooting/RADARR_CONNECTION_TROUBLESHOOTING.md) - VPN & API issues
- [Plex Playback Issues](docs/troubleshooting/PLAYBACK_ISSUE_RESOLUTION.md) - Remote access & buffering fixes
- [qBittorrent Performance](docs/troubleshooting/QB_PERFORMANCE_TROUBLESHOOTING.md) - Speed optimization
- [Network Latency](docs/troubleshooting/EERO_LATENCY_FIX_GUIDE.md) - Eero mesh fixes
- [General Troubleshooting](docs/troubleshooting/general-troubleshooting.md) - Common issues

### 🏗️ Architecture (`docs/architecture/`)
- [Architecture Details](docs/architecture/architecture.md)
- [Network Setup](docs/architecture/network-setup.md)
- [Security Hardening](docs/architecture/security.md)
- [Gaming Network](docs/architecture/gaming-network.md)
- [Security Cameras](docs/architecture/security-cameras.md)

### 📊 Reports & Audits (`docs/reports/`)
- [Infrastructure Audit](docs/reports/infrastructure/running-infrastructure-audit.md)
- [Media Corruption Scans](docs/reports/infrastructure/media-corruption-scanning.md)
- [Duplicate Media Analysis](docs/reports/duplicate-media/)

## 📊 Monitoring Stack

### Included Services
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **Alertmanager**: Notifications
- **Exporters**: Node, cAdvisor, Plex, Speedtest, Blackbox

### Access
- **Grafana**: http://localhost:3000 (default credentials must be changed on first login; do not leave at `admin/admin`)
- **Prometheus**: http://localhost:9090
- **Plex**: http://localhost:32400/web

## 🔧 Maintenance & Automation

### Automated Scripts
- **Health Checks**: `./scripts/health-checks/system-health.sh`
- **Backups**: `./scripts/backup/backup-media.sh`
- **Maintenance**: `./scripts/maintenance/maintenance.sh`

## Contributing
Personal home lab; not accepting PRs. Feel free to open issues if something in the documentation is unclear or wrong — feedback from people who've shipped similar setups is welcome.

## License
MIT for the scripts, configs, and runbooks in this repo. Documentation is CC-BY-4.0 — use any of it as a starting point for your own lab.
