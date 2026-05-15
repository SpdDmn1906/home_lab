# GEMINI.md - Home Lab Infrastructure Context

This file provides instructional context for AI agents (like Gemini CLI) interacting with the **Home Lab Datacenter Infrastructure** project.

## 🏗️ Project Overview
This is a comprehensive, production-like home datacenter setup managed via **Infrastructure as Code (IaC)** principles. It automates the deployment and management of a media server, networking infrastructure, and a robust monitoring stack.

### Core Technologies
- **Orchestration:** Docker Compose
- **Provisioning:** Terraform (manages Docker resources and service modules)
- **Configuration Management:** Ansible (system hardening, network config, service deployment)
- **Monitoring:** Prometheus, Grafana, Alertmanager, and various exporters (Node, cAdvisor, Plex, Speedtest)
- **Media Stack:** Plex Media Server + STARR stack (Sonarr, Radarr, Prowlarr, qBittorrent)
- **Automation:** Bash scripts for health checks, backups, and advanced media integrity scanning (FFmpeg-based)

---

## 🚀 Key Operational Workflows

### 1. Infrastructure Management
The primary entry point for managing the infrastructure is the `infrastructure-manager.sh` script.

| Task | Command |
| :--- | :--- |
| **Initialize** | `./scripts/root_utils/infrastructure-manager.sh init` |
| **Plan Changes** | `./scripts/root_utils/infrastructure-manager.sh plan` |
| **Deploy** | `./scripts/root_utils/infrastructure-manager.sh deploy` |
| **Verify Health** | `./scripts/root_utils/infrastructure-manager.sh verify` |
| **Show Status** | `./scripts/root_utils/infrastructure-manager.sh status` |

### 2. Media Integrity & Maintenance
The project contains an extensive suite of scripts for maintaining media library health, specifically focused on detecting corruption.

- **Adaptive Scanning:** `./scripts/adaptive_corruption_scan.sh` (Multi-phase scan using FFmpeg sampling and full decoding).
- **Health Checks:** `./scripts/health-checks/system-health.sh`
- **Backups:** `./scripts/backup/backup-media.sh`

### 3. Fortress Mode (Offline Operations)
Designed for local independence during WAN outages.

- **Plex Config**: `allowedNetworks` must be `192.168.1.0/24` (CIDR) to allow local auth.
- **Fortress Guard**: `/opt/homelab/scripts/fortress/plex-fortress-guard.sh` monitored via systemd timer. Blocks `plex.tv` to force authentication caching.
- **DNS**: Primary DNS should be local (AdGuard/Unbound) to ensure resolution without WAN.

---

## 📁 Directory Structure & Purpose

- `ansible/`: Playbooks and roles for system-level configuration and service setup.
- `docker/`: Docker Compose files for manual or orchestrated deployment.
- `terraform/`: IaC modules for provisioning Docker containers and volumes.
- `monitoring/`: Configuration files for the Prometheus/Grafana stack.
- `scripts/`:
    - `root_utils/`: Core management scripts (e.g., `infrastructure-manager.sh`).
    - `diagnostics/`: System and network diagnostic tools.
    - `fixes/`: Automated repair scripts for common issues (e.g., CIFS mounts).
    - `maintenance/`: Routine maintenance tasks.
- `docs/`:
    - `architecture/`: Design diagrams and high-level overviews.
    - `guides/`: Step-by-step setup and operations guides.
    - `troubleshooting/`: Solutions for known issues (e.g., Eero latency, Plex playback).
    - `reports/`: Results from audits and corruption scans.

---

## 🛠️ Development & Contribution Guidelines

### 1. Environment Configuration
- Always use `env.template` to create a `.env` file before deployment.
- Project-specific overrides (e.g., for `mediaserver`) are found in `config/`.

### 2. Infrastructure Changes
- **Do not** manually modify Docker containers or system configs. Use Terraform or Ansible to ensure state consistency.
- Terraform state is currently managed locally (`terraform/terraform.tfstate`).

### 3. Scripting Standards
- Most scripts use `set -euo pipefail` for robustness.
- Use the unified logging functions found in `infrastructure-manager.sh` for new utility scripts.
- Parallel processing (e.g., using `xargs` or background workers) is preferred for media scanning tasks.

### 4. Documentation
- Update the relevant `docs/` file whenever an architectural change is made.
- New reports should be placed in `docs/reports/` and indexed if possible.

---

## 📡 Networking Context
- **Primary Subnet:** `192.168.1.0/24`
- **Main Server:** `192.168.1.11` (Media Server / Docker Host)
- **NAS:** `192.168.1.20` (Synology)
- **Gateway:** `192.168.1.1` (Asus Router)

*Note: This project aims for a "Unified Network" topology, eliminating double NAT by using bridge modes for ISPs and mesh extensions.*
