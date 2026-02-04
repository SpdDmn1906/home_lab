# Quick Start Guide

## Prerequisites

- Docker and Docker Compose installed
- Basic knowledge of command line
- Access to your media server

## Initial Setup (5 Steps)

### Step 1: Clone/Download Repository

```bash
cd /path/to/your/home/lab
# Repository should be here
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp env.template .env

# Edit .env with your settings
nano .env
```

**Key Settings to Configure:**
- `MEDIA_ROOT`: Path to your media files
- `TZ`: Your timezone
- `GRAFANA_ADMIN_PASSWORD`: Change default password
- Paths for configs, data, backups

### Step 3: Create Required Directories

```bash
# Create directory structure
mkdir -p docker/monitoring/{prometheus/{rules},grafana/{provisioning/{datasources,dashboards},dashboards},loki,promtail}
mkdir -p backups logs
```

### Step 4: Review Docker Compose Configuration

```bash
# Review docker-compose.yml
cd docker
cat docker-compose.yml

# Adjust paths, ports, or services as needed
nano docker-compose.yml
```

### Step 5: Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## Access Services

After starting, access services at:

- **Grafana**: http://localhost:3000 (admin/admin - change password!)
- **Prometheus**: http://localhost:9090
- **Plex**: http://localhost:32400/web
- **Sonarr**: http://localhost:8989
- **Radarr**: http://localhost:7878
- **Prowlarr**: http://localhost:9696
- **qBittorrent**: http://localhost:8080

## Initial Configuration

### Grafana Setup

1. Login at http://localhost:3000
2. Change default password
3. Add Prometheus data source (should be auto-configured)
4. Import dashboards (if available)

### Plex Setup

1. Access http://localhost:32400/web
2. Sign in or create account
3. Add libraries (Movies, TV Shows)
4. Configure settings (see plex-optimization.md)

### STARR Stack Setup

1. Access each service (Sonarr, Radarr, Prowlarr)
2. Configure download client (qBittorrent)
3. Add indexers (via Prowlarr)
4. Configure media paths
5. Add root folders

## Next Steps

### 1. Set Up Monitoring

```bash
# Run health check
./scripts/health-checks/system-health.sh

# Check Docker containers
./scripts/health-checks/docker-health.sh
```

### 2. Configure Backups

```bash
# Test backup script
./scripts/backup/docker-backup.sh

# Set up cron job (optional)
crontab -e
# Add: 0 2 * * * /path/to/scripts/backup/docker-backup.sh
```

### 3. Optimize Network

- Review network-setup.md
- Configure router settings
- Optimize QoS settings

### 4. Secure Your Setup

- Review security.md
- Change default passwords
- Set up firewall rules
- Enable 2FA where possible

### 5. Address Specific Issues

**Boot Errors:**
- Review troubleshooting.md
- Run diagnostics
- Check disk health

**Plex Performance:**
- Review plex-optimization.md
- Enable hardware acceleration
- Optimize settings

**Network Issues:**
- Review network-setup.md
- Run network diagnostics
- Optimize router configuration

## Daily Operations

### Check System Health

```bash
# Quick health check
./scripts/health-checks/system-health.sh

# Docker health check
./scripts/health-checks/docker-health.sh
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f plex

# Last 100 lines
docker-compose logs --tail=100 plex
```

### Update Services

```bash
# Update all services
./scripts/maintenance/update-services.sh

# Or manually
cd docker
docker-compose pull
docker-compose up -d
```

### Backup

```bash
# Manual backup
./scripts/backup/docker-backup.sh

# Check backups
ls -lh backups/
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs <service-name>

# Check container status
docker-compose ps

# Restart service
docker-compose restart <service-name>
```

### Port Conflicts

```bash
# Check what's using a port
sudo lsof -i :32400

# Change port in docker-compose.yml
# Edit ports section for the service
```

### Permission Issues

```bash
# Check file permissions
ls -la /path/to/media

# Fix permissions
sudo chown -R $USER:$USER /path/to/media
chmod -R 755 /path/to/media
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean up Docker
./scripts/maintenance/cleanup.sh

# Remove old backups
find backups/ -name "*.tar.gz" -mtime +30 -delete
```

## Maintenance Schedule

### Daily
- Quick health check (automated recommended)
- Monitor active services

### Weekly
- Review logs for errors
- Check disk space
- Run backups

### Monthly
- Update services
- Review performance metrics
- Security updates
- Clean up old backups

### Quarterly
- Full system review
- Network optimization
- Security audit
- Hardware health check

## Getting Help

1. **Check Documentation:**
   - README.md - Overview
   - architecture.md - System design
   - troubleshooting.md - Common issues
   - network-setup.md - Network configuration
   - plex-optimization.md - Plex tuning
   - security.md - Security hardening

2. **Check Logs:**
   - Docker logs: `docker-compose logs`
   - System logs: `journalctl`
   - Application logs: Service-specific locations

3. **Run Diagnostics:**
   - System health: `./scripts/health-checks/system-health.sh`
   - Docker health: `./scripts/health-checks/docker-health.sh`
   - Network: See network-setup.md

4. **Community Resources:**
   - Plex Forums
   - Reddit (r/plex, r/homelab, r/selfhosted)
   - Stack Overflow
   - GitHub Issues (for specific projects)

## Important Notes

- **Always backup before major changes**
- **Test changes in non-production first** (if possible)
- **Keep documentation updated**
- **Monitor system resources**
- **Review logs regularly**
- **Keep services updated**
- **Follow security best practices**

## Common Commands Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart service
docker-compose restart <service>

# View logs
docker-compose logs -f <service>

# Update services
docker-compose pull && docker-compose up -d

# Health checks
./scripts/health-checks/system-health.sh
./scripts/health-checks/docker-health.sh

# Backup
./scripts/backup/docker-backup.sh

# Cleanup
./scripts/maintenance/cleanup.sh

# Update
./scripts/maintenance/update-services.sh
```



