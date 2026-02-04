# Home Lab Datacenter Infrastructure

A comprehensive, production-like home datacenter setup with monitoring, automation, and DevOps best practices.

## 🏗️ Architecture Overview

### Network Topology
- **Internet**: Comcast Xfinity 2GB with Xfinity Xfi modem (bridge mode)
- **Routers**:
  - Primary: Asus Nighthawk RAX50 (DHCP, DNS, main WiFi "SC Home")
  - Mesh Extension: Amazon Eero (3 nodes in bridge mode, "SC Home_Ext")
- **Unified Network**: Single 192.168.1.0/24 subnet (eliminated double NAT)
- **Total Devices**: ~30+ devices
  - **Computing**: Desktop media server, laptops, tablets, phones
  - **Media**: TVs, streaming devices
  - **Security Cameras**:
    - 1x Nest Outdoor WiFi Cam
    - 2x Nest Indoor WiFi Cams
    - 2x Eufy Outdoor WiFi Cams (with Homebase)
  - **Security System**: Abode with 2 motion sensors, 5 entry point monitors
  - **IoT Devices**: Smart plugs, bulbs, outlets, LED strips
  - **Gaming**: PS5, Nintendo Switch

### Infrastructure Components

#### Storage
- **Synology NAS**: 2-bay, 4TB (TV shows, movies)
- **External HDD**: 2TB (movies, TV shows)
- **Photo/Video**: Large files for editing business

#### Gaming & Entertainment
- **PS5**: PlayStation Plus membership services
- **Nintendo Switch**: Gaming console

#### Security Systems
- **Nest Cameras**: 1 outdoor + 2 indoor WiFi cams
- **Eufy Cameras**: 2 outdoor cams with Homebase
- **Abode Security**: 2 motion sensors + 5 entry monitors

#### Smart Home (30 devices)
- TVs, mobile devices (iPhones, iPads, Android tablet)
- Smart plugs, bulbs, outdoor outlets, LED strips

#### Compute
- **Media Server/Home Lab Server**: Main desktop running Docker containers
  - STARR stack (Sonarr, Radarr, etc.)
  - Plex Media Server (local + external users)
  - Prometheus (metrics collection)
  - Grafana (visualization)
  - Future containerized services

## 🎯 Current Challenges & Solutions

### Issues Resolved ✅
1. ✅ **CIFS Mount Errors** - Fixed with optimized mount options (`noserverino`, `cache=none`, `actimeo=0`)
2. ✅ **Duplicate Media Cleanup** - 116 duplicates quarantined, quality-based retention implemented
3. ✅ **Hardware Issues Identified** - Failing S.M.A.R.T. drive documented and safe to remove
4. ✅ **System Stability** - CIFS handle errors eliminated, boot process manageable

### Current System Status ✅
**Media Server Optimization**: COMPLETE - All critical issues resolved
**CIFS Mounts**: Optimized with performance enhancements
**Duplicate Cleanup**: 116 duplicates quarantined, quality preserved
**Hardware**: Failing drive identified (safe to remove)
**STARR Ready**: Full integration prepared for service activation

### Future Enhancements 🔄
1. **STARR Activation** - Enable Radarr/Sonarr for automated media management
2. **UPS Implementation** - Power stability and protection
3. **Advanced Monitoring** - Prometheus/Grafana for system observability
4. ❌ No system/network performance visibility - **Action**: Comprehensive monitoring stack
5. ❓ Configuration optimization uncertainty - **Action**: Documentation and best practices

### New Goals Added
6. 🎬 **4K Local Playback** - Multiple devices, zero lag/buffering, HEVC compatibility
7. 🌐 **External 1080p Streaming** - No interference with local 4K performance
8. 🏰 **Fortress Mode** - Complete local independence when internet is down

## 📁 Project Structure

```
home_lab/
├── docker/                          # Proposed Docker Compose (NOT automatically deployed)
│   ├── docker-compose.yml           # Local proposal (running configs live on server under /home/youruser/Docker/*)
│   └── monitoring/                  # Proposal monitoring configs
├── monitoring/                      # Monitoring configurations
│   ├── prometheus/                  # Prometheus configs and rules
│   │   ├── prometheus.yml          # Main Prometheus configuration
│   │   ├── rules.yml               # Alerting rules
│   │   └── alertmanager.yml        # Alert manager configuration
│   ├── grafana/                     # Grafana dashboards and datasources
│   │   ├── dashboards/             # Dashboard JSON files
│   │   │   ├── system-overview.json
│   │   │   └── plex-dashboard.json
│   │   └── provisioning/           # Auto-configuration
│   │       ├── dashboards/         # Dashboard provisioning
│   │       └── datasources/        # Datasource provisioning
│   └── exporters/                   # Custom exporters configs
│       └── blackbox.yml            # Blackbox exporter configuration
├── scripts/                         # Automation and utility scripts
│   ├── backup/                      # Backup automation
│   │   └── backup-media.sh         # Media and config backup script
│   ├── health-checks/               # Health monitoring scripts
│   │   └── system-health.sh        # Comprehensive health check
│   └── maintenance/                 # Maintenance tasks
│       └── maintenance.sh           # Routine maintenance script
├── docs/                            # Documentation
│   ├── architecture.md              # Detailed architecture guide
│   ├── network-setup.md             # Network configuration guide
│   ├── troubleshooting.md           # Troubleshooting runbooks
│   └── security.md                  # Security hardening guide
├── ansible/                         # Infrastructure as Code (future)
├── env.template                     # Environment variables template
├── docs/quick-start.md              # Quick start guide
└── README.md                        # This file
```

## 🚀 Quick Start

### Option 1: Automated Infrastructure Setup (Recommended)
```bash
# Complete infrastructure management with Terraform + Ansible
./infrastructure-manager.sh init    # Initialize infrastructure
./infrastructure-manager.sh plan    # Plan changes
./infrastructure-manager.sh deploy  # Deploy everything
./infrastructure-manager.sh verify  # Verify deployment
```

### Option 2: Manual Network Migration First
```bash
# If you haven't unified your network yet
cat NETWORK_MIGRATION_PLAN.md       # Read migration guide
./network_test.sh                   # Test current network issues
# Follow manual router configuration steps
# Then proceed with infrastructure setup
```

### Option 3: Quick Setup (15 minutes)
```bash
# Follow the streamlined setup
cat docs/quick-start.md
```

### Option 4: Detailed Setup
1. **Review Documentation**
   ```bash
   cat docs/architecture.md
   cat docs/network-setup.md
   ```

2. **Configure Environment**
   ```bash
   cp env.template .env
   # Edit .env with your specific paths and configurations
   ```

3. **Start Services**
   ```bash
   cd docker
   docker-compose up -d
   ```

4. **Access Services**
   - Grafana: http://localhost:3000 (default: admin/admin - CHANGE IMMEDIATELY!)
   - Prometheus: http://localhost:9090
   - Plex: http://localhost:32400/web

## 📊 Monitoring Stack

### Included Services
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert handling and notifications
- **Node Exporter**: System metrics (CPU, memory, disk, network)
- **cAdvisor**: Docker container metrics
- **Plex Exporter**: Plex media server metrics
- **Speedtest Exporter**: Internet speed monitoring
- **Blackbox Exporter**: Network endpoint monitoring

### Pre-configured Dashboards
- **System Overview**: CPU, memory, disk, network usage
- **Plex Dashboard**: Media server performance and sessions

### Alerting Rules
- System resource alerts (CPU, memory, disk)
- Service availability alerts
- Network connectivity alerts
- Plex performance alerts
- Temperature monitoring

### Notification Channels
- Email alerts (configurable)
- Slack integration (optional)
- Pushover notifications (optional)
- Discord webhooks (optional)

## 🔧 Maintenance & Automation

### Automated Scripts
- **Health Checks**: `./scripts/health-checks/system-health.sh`
- **Backups**: `./scripts/backup/backup-media.sh`
- **Maintenance**: `./scripts/maintenance/maintenance.sh`

### Maintenance Schedule
- **Daily**: Automated health checks and log rotation
- **Weekly**: Automated backups and system updates
- **Monthly**: Security updates, backup verification, and system review

### Manual Tasks
- Monitor Grafana dashboards regularly
- Review alert notifications
- Update documentation as infrastructure changes
- Test backup restores periodically

## 📚 Documentation

- [Documentation Index](DOCUMENTATION_INDEX.md) - **Complete documentation reference**
- [Quick Start Guide](docs/quick-start.md) - Get up and running in 15 minutes
- [Network Migration Plan](NETWORK_MIGRATION_PLAN.md) - Unify your dual-network setup
- [Network Infrastructure Accomplishments](NETWORK_INFRASTRUCTURE_ACCOMPLISHMENTS.md) - Complete network migration documentation
- [Server Audit Analysis](SERVER_AUDIT_ANALYSIS.md) - **COMPREHENSIVE SERVER AUDIT** (Based on actual SSH audit)
- [New Goals Implementation Guide](NEW_GOALS_IMPLEMENTATION_GUIDE.md) - **STEP-BY-STEP 4K & FORTRESS MODE IMPLEMENTATION** ⭐ NEW GOALS
- [Plex 4K & Fortress Mode Strategy](PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md) - **4K PERFORMANCE & LOCAL INDEPENDENCE STRATEGY**
- [Comprehensive Final Review](COMPREHENSIVE_FINAL_REVIEW.md) - **COMPLETE STRATEGIC REVIEW & ROADMAP** ⭐ START HERE
- [Optimized fstab & Configurations](OPTIMIZED_FSTAB_AND_CONFIGURATIONS.md) - **CORRECTED FSTAB WITH DOCKER-COMPATIBLE PATHS**
- [Service Optimization Recommendations](SERVICE_OPTIMIZATION_RECOMMENDATIONS.md) - **PLEX & STARR STACK PERFORMANCE TUNING**
- [Plex Remote Access Troubleshooting](PLEX_REMOTE_ACCESS_TROUBLESHOOTING.md) - **REMOTE ACCESS FIX** ✅ RESOLVED
- [Network Configuration Reference](NETWORK_CONFIGURATION_REFERENCE.md) - **PORT FORWARDING & NETWORK SETTINGS** ⭐ QUICK REFERENCE
- [Eero Latency Analysis](EERO_LATENCY_ANALYSIS.md) - **EERO MESH LATENCY ISSUE ANALYSIS** ⚠️
- [Eero Latency Fix Guide](EERO_LATENCY_FIX_GUIDE.md) - **STEP-BY-STEP LATENCY FIX** (30 minutes)
- [Network Service & CIFS Fixes](NETWORK_SERVICE_AND_CIFS_FIXES.md) - **NETWORK MANAGER ANALYSIS & CIFS ERROR FIXES**
- [Boot Errors & Network Fixes](BOOT_ERRORS_AND_NETWORK_FIXES.md) - **BOOT ERRORS & NETWORK SERVICE FIXES**
- [Immediate Action Plan](IMMEDIATE_ACTION_PLAN.md) - **STEP-BY-STEP FIXES** (Ready to execute)
- [Current Infrastructure Analysis](CURRENT_INFRASTRUCTURE_ANALYSIS.md) - Complete analysis of running services
- [Infrastructure Recommendations](INFRASTRUCTURE_RECOMMENDATIONS.md) - Prioritized action plan
- [Running Infrastructure Audit](docs/running-infrastructure-audit.md) - Security audit report
- [STARR Stack Analysis](docs/starr-stack-analysis.md) - STARR stack security analysis
- [STARR Stack Migration Guide](docs/starr-stack-migration-guide.md) - Migration to secure configuration
- [DNS Setup Guide](DNS_SETUP_GUIDE.md) - Name resolution for reliable device access
- [AdGuard Home Setup Guide](ADGUARD_HOME_SETUP.md) - **ADGUARD HOME + UNBOUND DNS INFRASTRUCTURE** ⭐ NEW
- [Advanced Features Guide](HOMELAB_ADVANCED_FEATURES.md) - AdGuard Home, parental controls, remote access, AI assistant
- [Network Latency Improvement Analysis](NETWORK_LATENCY_IMPROVEMENT_ANALYSIS.md) - **LATENCY IMPROVEMENT VERIFIED** ✅
- [Device Integration Guide](DEVICE_INTEGRATION.md) - Security cameras, gaming consoles, and smart home setup
- [Architecture Details](docs/architecture.md) - Complete infrastructure overview
- [Network Setup Guide](docs/network-setup.md) - Network configuration and optimization
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
- [Security Hardening](docs/security.md) - Security best practices and implementation
- [Infrastructure Management](INFRASTRUCTURE_MANAGEMENT.md) - Terraform & Ansible IaC setup
- [Media Corruption Scanning](docs/media-corruption-scanning.md) - ⭐ **Production adaptive 2-phase scanning system** (2026-01-09)

## 🚀 **Current Status: Network Migration Complete!**

✅ **Unified Network**: Single 192.168.1.0/24 network working perfectly
✅ **Performance Goals**: 2-6ms latency, zero packet loss, excellent stability
✅ **Device Connectivity**: All devices communicate seamlessly
✅ **DNS Setup Ready**: Static IPs and name resolution configured
✅ **Infrastructure Ready**: Terraform + Ansible automation deployed

## 🏗️ Infrastructure Management

This home lab uses **Infrastructure as Code** principles with Terraform and Ansible for complete automation and management.

### Terraform (Infrastructure State)
- **Network Configuration**: VLANs, DHCP, DNS, firewall rules
- **Docker Services**: Container deployment and configuration
- **Monitoring Setup**: Prometheus, Grafana, Alertmanager
- **Security Policies**: SSH, firewall, access controls

### Ansible (Configuration Management)
- **Server Hardening**: System security, package management
- **Service Deployment**: Application installation and configuration
- **Backup Automation**: Scheduled backups with encryption
- **Monitoring**: Health checks, alerting setup

### Getting Started with IaC

1. **Initialize Infrastructure**:
   ```bash
   ./infrastructure-manager.sh init
   ```

2. **Configure Your Environment**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

3. **Deploy Everything**:
   ```bash
   ./infrastructure-manager.sh deploy
   ```

4. **Monitor and Manage**:
   ```bash
   ./infrastructure-manager.sh status    # Check status
   ./infrastructure-manager.sh backup    # Backup state
   ./infrastructure-manager.sh verify    # Health checks
   ```

### Key Benefits

- **Version Control**: All infrastructure changes tracked in Git
- **Reproducible**: Deploy identical environments anywhere
- **Automated**: No manual configuration steps
- **Auditable**: Complete change history and rollback capability
- **Scalable**: Easy to add new services and features

### Directory Structure

```
terraform/              # Infrastructure as Code
├── main.tf            # Main Terraform configuration
├── variables.tf       # Variable definitions
├── terraform.tfvars   # Your custom values
└── modules/           # Reusable components
    ├── network/       # Network configuration
    ├── docker/        # Container management
    ├── monitoring/    # Observability stack
    ├── security/      # Security policies
    └── backup/        # Backup systems

ansible/                # Configuration Management
├── playbooks/         # Deployment playbooks
├── roles/             # Reusable roles
├── inventory/         # Host inventories
└── vars/             # Configuration variables
```

## 🤝 Contributing

This is a personal home lab, but structured for professional practices. The IaC approach makes it easy to contribute improvements and share configurations.

## 📝 License

Personal use only.

