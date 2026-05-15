# Home Lab Datacenter Infrastructure

A comprehensive, production-like home datacenter setup with monitoring, automation, and DevOps best practices.

## 🏗️ Architecture Overview

### Network Topology
- **Internet**: Comcast Xfinity 2GB with Xfinity Xfi modem (bridge mode)
- **Routers**:
  - Primary: Asus Nighthawk RAX50 (DHCP, DNS, main WiFi "SC Home")
  - Mesh Extension: Amazon Eero (3 nodes in bridge mode, "SC Home_Ext")
- **Unified Network**: Single 192.168.1.0/24 subnet (eliminated double NAT)
- **Total Devices**: ~30+ devices (Media Server, IoT, Security, Gaming)

### Infrastructure Components

#### Compute
- **Media Server/Home Lab Server**: Main desktop running Docker containers
  - STARR stack (Sonarr, Radarr, etc.)
  - Plex Media Server (local + external users)
  - Prometheus/Grafana (monitoring)

#### Storage
- **Synology NAS**: 2-bay, 4TB (TV shows, movies)
- **External HDD**: 2TB (movies, TV shows)

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
- **Grafana**: http://localhost:3000 (default: admin/admin)
- **Prometheus**: http://localhost:9090
- **Plex**: http://localhost:32400/web

## 🔧 Maintenance & Automation

### Automated Scripts
- **Health Checks**: `./scripts/health-checks/system-health.sh`
- **Backups**: `./scripts/backup/backup-media.sh`
- **Maintenance**: `./scripts/maintenance/maintenance.sh`

## 🤝 Contributing
This is a personal home lab, managed via Infrastructure as Code.

## 📝 License
Personal use only.
