# Immediate Action Plan - Based on Server Audit

**Created**: 2025-12-29
**Based On**: Comprehensive SSH audit of mediaserver (192.168.1.11)
**Priority**: 🔴 **CRITICAL FIXES REQUIRED**

---

## 🚨 Critical Fixes (Do Today)

> **NEW**: See [BOOT_ERRORS_AND_NETWORK_FIXES.md](BOOT_ERRORS_AND_NETWORK_FIXES.md) for boot error fixes and network service conflicts.

### Fix #1: STARR Stack Root Access (2 hours)

**Why Critical**: All 7 STARR services running as root (PUID=0, PGID=0) - Complete host compromise risk if breached.

**Steps:**

```bash
# SSH into server
ssh youruser@192.168.1.11

# Navigate to STARR stack directory
cd /home/youruser/Docker/config/data_gluetun

# Backup current configuration
cp docker-compose.yml docker-compose.yml.backup-$(date +%Y%m%d_%H%M%S)

# Update PUID/PGID (your actual IDs: UID=1000, GID=1004)
sed -i 's/PUID=0/PUID=1000/g' docker-compose.yml
sed -i 's/PGID=0/PGID=1004/g' docker-compose.yml

# Fix file ownerships
sudo chown -R 1000:1004 /usr/local/bin/qbittorrent/config
sudo chown -R 1000:1004 /usr/local/bin/radarr/config
sudo chown -R 1000:1004 /usr/local/bin/sonarr/config
sudo chown -R 1000:1004 /usr/local/bin/prowlarr/data
sudo chown -R 1000:1004 /usr/local/bin/flaresolverr/data

# Restart services
docker-compose down
docker-compose up -d

# Verify services started correctly
docker-compose ps
docker-compose logs -f  # Watch for errors (Ctrl+C to exit)

# Test each service:
# - qBittorrent: http://192.168.1.11:8080
# - Radarr: http://192.168.1.11:7878
# - Sonarr: http://192.168.1.11:8989
# - Prowlarr: http://192.168.1.11:9696
```

**Verification:**
```bash
# Check services are not running as root
docker exec qbittorrent id
# Should show: uid=1000(youruser) gid=1004(youruser)

docker exec radarr id
# Should show: uid=1000(youruser) gid=1004(youruser)
```

**Rollback (if needed):**
```bash
cd /home/youruser/Docker/config/data_gluetun
cp docker-compose.yml.backup-* docker-compose.yml
docker-compose down
docker-compose up -d
```

---

### Fix #2: Change Grafana Password (5 minutes)

**Why Critical**: Default weak password (adminpwd) allows unauthorized access.

**Steps:**

```bash
# Option 1: Change via Grafana UI (immediate)
# 1. Open browser: http://192.168.1.11:3000
# 2. Login: admin / adminpwd
# 3. Click user icon (bottom left) > Preferences > Change Password
# 4. Set strong password (save it securely!)

# Option 2: Update compose file (recommended for long-term)
cd /home/youruser/Docker/DevOps-Docker-Prometheus-Grafana-IaaC

# Backup
cp docker-compose.yml docker-compose.yml.backup-$(date +%Y%m%d)

# Create .env file with secure password
echo "GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32)" > .env

# Update compose file
sed -i 's/GF_SECURITY_ADMIN_PASSWORD=adminpwd/GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}/' docker-compose.yml

# Restart Grafana (this will require new login)
docker-compose restart grafana
```

**Verification:**
```bash
# Try accessing Grafana
curl -u admin:adminpwd http://192.168.1.11:3000/api/user
# Should return 401 (unauthorized) after password change
```

---

## 🟡 High Priority Fixes (This Week)

### Fix #3: Node Exporter Security (15 minutes)

**Why Important**: Running as root with privileged mode bypasses all container security.

**Steps:**

```bash
cd /home/youruser/Docker/DevOps-Docker-Prometheus-Grafana-IaaC

# Backup
cp docker-compose.yml docker-compose.yml.backup-nodeexporter-$(date +%Y%m%d)

# Edit docker-compose.yml
nano docker-compose.yml

# In nodeexporter service, change:
# FROM:
#   user: root
#   privileged: true
# TO:
#   # Remove user: root
#   # Remove privileged: true
#   security_opt:
#     - no-new-privileges:true
#   cap_drop:
#     - ALL
#   cap_add:
#     - SYS_TIME

# Restart nodeexporter
docker-compose stop nodeexporter
docker-compose rm nodeexporter
docker-compose up -d nodeexporter

# Verify it's working
docker logs nodeexporter
curl http://localhost:9100/metrics | head -20
```

**Verification:**
```bash
# Check Prometheus is still scraping
# Access: http://192.168.1.11:9090
# Query: up{job="node"}
# Should return value of 1
```

---

### Fix #4: Storage Cleanup (2-3 hours)

**Why Critical**: External drive at 98%, NAS at 100% - Services will fail soon.

**Steps:**

```bash
# Step 1: Find largest files/directories
echo "=== External Drive Largest Directories ==="
du -h /external/media 2>/dev/null | sort -rh | head -20

echo "=== NAS Largest Directories ==="
du -h /data/media 2>/dev/null | sort -rh | head -20

# Step 2: Find large files
echo "=== Large Files (>10GB) on External ==="
find /external/media -type f -size +10G -ls 2>/dev/null

echo "=== Large Files (>10GB) on NAS ==="
find /data/media -type f -size +10G -ls 2>/dev/null

# Step 3: Clean up Docker
docker system df  # Check Docker disk usage
docker image prune -a  # Remove unused images (careful!)
docker volume prune  # Remove unused volumes (careful!)

# Step 4: Clean completed downloads
# Check qBittorrent for completed downloads that can be removed
# Access: http://192.168.1.11:8080
# Remove completed torrents (keep only seeding if desired)

# Step 5: Check for duplicates
# Consider using tools like fdupes or rdfind
# sudo apt-get install fdupes
# fdupes -r /external/media > duplicates.txt

# Step 6: Remove old logs
docker logs --tail 1000 container_name > /dev/null  # Clear logs
# Or configure log rotation
```

**Target**: Free up at least 200GB on external drive, 500GB on NAS

---

### Fix #5: Timezone Standardization (5 minutes)

**Why Important**: Sonarr uses UTC while others use America/New_York - causes scheduling issues.

**Steps:**

```bash
cd /home/youruser/Docker/config/data_gluetun

# Backup
cp docker-compose.yml docker-compose.yml.backup-timezone-$(date +%Y%m%d)

# Update Sonarr timezone
sed -i 's/TZ=Etc\/UTC/TZ=America\/New_York/g' docker-compose.yml

# Restart Sonarr
docker-compose restart sonarr

# Verify
docker exec sonarr date
# Should show America/New_York time
```

---

## 📋 Quick Reference Commands

### Check Service Status
```bash
# All containers
docker ps -a

# STARR stack
cd /home/youruser/Docker/config/data_gluetun && docker-compose ps

# Monitoring stack
cd /home/youruser/Docker/DevOps-Docker-Prometheus-Grafana-IaaC && docker-compose ps
```

### Check Resource Usage
```bash
# Container stats
docker stats --no-stream

# Disk usage
df -h

# Docker disk usage
docker system df
```

### Check Logs
```bash
# STARR services
docker logs qbittorrent --tail 50
docker logs radarr --tail 50
docker logs sonarr --tail 50

# Monitoring
docker logs prometheus --tail 50
docker logs grafana --tail 50
docker logs nodeexporter --tail 50

# Plex
docker logs plex --tail 50
```

### Test Services
```bash
# Test STARR services
curl -I http://localhost:8080  # qBittorrent
curl -I http://localhost:7878  # Radarr
curl -I http://localhost:8989  # Sonarr

# Test monitoring
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3000/api/health  # Grafana
curl http://localhost:9100/metrics | head -5  # Node Exporter
```

---

## ✅ Post-Fix Verification Checklist

After completing fixes, verify:

### Security
- [ ] No STARR services running as root
- [ ] Node Exporter not privileged
- [ ] Grafana password changed
- [ ] All services accessible

### Functionality
- [ ] qBittorrent WebUI accessible
- [ ] Radarr WebUI accessible
- [ ] Sonarr WebUI accessible
- [ ] Downloads working
- [ ] VPN connection active (check Gluetun logs)
- [ ] Prometheus scraping metrics
- [ ] Grafana dashboards loading
- [ ] Plex serving media

### Storage
- [ ] External drive usage below 90%
- [ ] NAS usage below 95%
- [ ] Cleanup procedures documented

### Performance
- [ ] Services starting correctly
- [ ] No error messages in logs
- [ ] Resource usage normal
- [ ] No port conflicts

---

## 🆘 Troubleshooting

### If Services Don't Start After Fix #1

```bash
# Check file permissions
ls -la /usr/local/bin/qbittorrent/config
ls -la /usr/local/bin/radarr/config

# Check logs for permission errors
docker-compose logs qbittorrent | grep -i permission
docker-compose logs radarr | grep -i permission

# Fix permissions if needed
sudo chown -R 1000:1004 /usr/local/bin/qbittorrent/config
sudo chmod -R 755 /usr/local/bin/qbittorrent/config
```

### If Node Exporter Stops Working After Fix #3

```bash
# Check if it needs SYS_TIME capability
docker logs nodeexporter

# May need to add:
# cap_add:
#   - SYS_TIME
```

### If Storage Cleanup Doesn't Help

```bash
# Check what's actually using space
du -h --max-depth=1 /external/media | sort -rh
du -h --max-depth=1 /data/media | sort -rh

# Consider moving media to new location
# Or adding new storage device
```

---

## 📞 Support

If you encounter issues:

1. **Check Logs**: `docker logs <container-name>`
2. **Rollback**: Use backup files created during fixes
3. **Document**: Note any issues encountered
4. **Review**: Check [SERVER_AUDIT_ANALYSIS.md](SERVER_AUDIT_ANALYSIS.md) for detailed information

---

**Priority Order**:
1. Fix #1 (STARR root access) - **Do First**
2. Fix #2 (Grafana password) - **Do After #1**
3. Fix #3 (Node Exporter) - **Do This Week**
4. Fix #4 (Storage) - **Do This Week**
5. Fix #5 (Timezone) - **Do This Week**

**Total Estimated Time**: ~6-8 hours
**Risk Level**: Low (with proper backups)
**Impact**: Eliminates critical security vulnerabilities

