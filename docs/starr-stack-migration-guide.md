# STARR Stack Migration Guide

## Overview

This guide helps you migrate from your current STARR stack configuration to the recommended, secure configuration. The migration addresses critical security issues and improves overall stability.

## 🚨 Critical Issues to Fix

### Priority 1: Security (Must Fix Immediately)

1. **Running as Root (PUID=0, PGID=0)**
   - **Risk**: Critical security vulnerability
   - **Fix**: Change to non-root user (1000:1000)
   - **Time**: 5 minutes

2. **Port Conflict (8080)**
   - **Risk**: Service failures
   - **Fix**: Change qBittorrent port to 8082
   - **Time**: 2 minutes

### Priority 2: Configuration (Should Fix Soon)

3. **Timezone Inconsistency**
   - **Risk**: Scheduling issues
   - **Fix**: Standardize to America/New_York
   - **Time**: 2 minutes

4. **Missing Health Checks**
   - **Risk**: Undetected failures
   - **Fix**: Add health checks
   - **Time**: 5 minutes

5. **Missing Resource Limits**
   - **Risk**: Resource exhaustion
   - **Fix**: Add CPU/memory limits
   - **Time**: 5 minutes

## 📋 Pre-Migration Checklist

- [ ] Read [STARR Stack Analysis](starr-stack-analysis.md)
- [ ] Identify your user ID: `id -u` and `id -g`
- [ ] Backup current docker-compose.yml
- [ ] Backup all service configurations
- [ ] Document current port mappings
- [ ] Note current volume paths
- [ ] Plan downtime window (15-30 minutes)

## 🔄 Migration Steps

### Step 1: Backup Current Configuration

```bash
# Navigate to your STARR stack directory
cd ~/Docker/config/data_gluetun

# Backup current compose file
cp docker-compose.yml docker-compose.yml.backup

# Backup service configs
sudo tar czf starr-config-backup-$(date +%Y%m%d).tar.gz \
  /usr/local/bin/qbittorrent/config \
  /usr/local/bin/radarr/config \
  /usr/local/bin/sonarr/config \
  /usr/local/bin/prowlarr/data \
  /usr/local/bin/flaresolverr/data
```

### Step 2: Find Your User ID

```bash
# Get your user ID and group ID
echo "UID: $(id -u)"
echo "GID: $(id -g)"

# Note these values - you'll need them
```

### Step 3: Secure Credentials File

```bash
# Secure the credentials file
sudo chmod 600 /home/youruser/Docker/config/data_gluetun/credentials.txt
sudo chown root:root /home/youruser/Docker/config/data_gluetun/credentials.txt
```

### Step 4: Update Docker Compose File

**Option A: Use Recommended File**

```bash
# Copy recommended configuration
cp /path/to/home_lab/docker/starr/docker-compose.yml.recommended docker-compose.yml

# Edit the file and update paths
nano docker-compose.yml
```

**Option B: Manual Update**

1. Update PUID/PGID:
   ```yaml
   environment:
     - PUID=1000  # Change from 0
     - PGID=1000  # Change from 0
   ```

2. Fix port conflict:
   ```yaml
   # In gluetun service
   ports:
     - 8082:8080/tcp  # Changed from 8080:8080
   ```

3. Standardize timezone:
   ```yaml
   # In sonarr service
   environment:
     - TZ=America/New_York  # Change from Etc/UTC
   ```

4. Add health checks, resource limits, security options (see recommended file)

### Step 5: Create/Update .env File

```bash
# Create .env file in your STARR directory.
# If you are deploying on mediaserver (192.168.1.11), start from the audited defaults:
cp /path/to/home_lab/config/mediaserver.env.example .env

# If you are deploying elsewhere, copy and adjust:
# cp /path/to/home_lab/config/mediaserver.env.example .env
# nano .env
```

### Step 6: Stop Current Services

```bash
# Stop all services gracefully
docker-compose down

# Verify all stopped
docker ps | grep -E "qbittorrent|radarr|sonarr|prowlarr|flaresolverr|gluetun"
# Should show no containers
```

### Step 7: Fix File Permissions

```bash
# Fix ownership of config directories (replace 1000:1000 with your UID:GID)
sudo chown -R 1000:1000 /usr/local/bin/qbittorrent/config
sudo chown -R 1000:1000 /usr/local/bin/radarr/config
sudo chown -R 1000:1000 /usr/local/bin/sonarr/config
sudo chown -R 1000:1000 /usr/local/bin/prowlarr/data
sudo chown -R 1000:1000 /usr/local/bin/flaresolverr/data
```

### Step 8: Start Services

```bash
# Validate configuration
docker-compose config

# Start services
docker-compose up -d

# Monitor startup
docker-compose logs -f
```

### Step 9: Verify Services

```bash
# Check all containers are running
docker-compose ps

# Check health status
docker-compose ps | grep -E "healthy|unhealthy"

# Test service access
curl http://localhost:8082  # qBittorrent (new port)
curl http://localhost:7878  # Radarr
curl http://localhost:8989  # Sonarr
curl http://localhost:9696  # Prowlarr
curl http://localhost:8191  # FlareSolverr
```

### Step 10: Update Service Configurations

**qBittorrent:**
- Access WebUI: http://localhost:8082 (new port)
- Verify settings are intact
- Test download functionality

**Radarr/Sonarr:**
- Access WebUIs: http://localhost:7878 and http://localhost:8989
- Verify download clients still configured
- Test search functionality

**Prowlarr:**
- Access WebUI: http://localhost:9696
- Verify indexers still configured
- Test indexer connectivity

> **Note**: If you are using Prowlarr, you generally do **not** need Jackett. This repo now treats **Jackett as deprecated** for your setup.

## 🔍 Verification Checklist

After migration, verify:

- [ ] All containers running (not as root)
- [ ] Services accessible on correct ports
- [ ] Health checks passing
- [ ] Downloads working
- [ ] Indexers functioning
- [ ] VPN connectivity verified
- [ ] Resource usage reasonable
- [ ] Logs showing no errors

## 🐛 Troubleshooting

### Services Won't Start

**Permission Errors:**
```bash
# Check file ownership
ls -la /usr/local/bin/*/config

# Fix ownership
sudo chown -R $(id -u):$(id -g) /usr/local/bin/*/config
```

**Port Already in Use:**
```bash
# Check what's using port 8080
sudo lsof -i :8080

# Stop conflicting service or change port
```

### Services Running but Not Accessible

**Check Network Mode:**
```bash
# Verify gluetun is running
docker ps | grep gluetun

# Check container network
docker inspect gluetun | grep NetworkMode
```

**Check VPN Connection:**
```bash
# Check gluetun logs
docker logs gluetun

# Verify VPN IP
docker exec gluetun curl -s ifconfig.me
```

### Performance Issues

**Check Resource Usage:**
```bash
# Check container resource usage
docker stats

# Adjust limits if needed
# Edit docker-compose.yml resource limits
```

## 📊 Post-Migration Monitoring

### Daily Checks

- Monitor container health: `docker-compose ps`
- Check resource usage: `docker stats`
- Review logs: `docker-compose logs --tail=50`

### Weekly Checks

- Verify VPN connectivity
- Check disk space usage
- Review download performance
- Test all services

### Monthly Checks

- Update container images
- Review and optimize resource limits
- Check for security updates
- Backup configurations

## 🔄 Rollback Procedure

If issues occur, rollback:

```bash
# Stop new services
docker-compose down

# Restore backup
cp docker-compose.yml.backup docker-compose.yml

# Restore configs if needed
sudo tar xzf starr-config-backup-YYYYMMDD.tar.gz

# Restart with old config
docker-compose up -d
```

## 📚 Additional Resources

- [STARR Stack Analysis](starr-stack-analysis.md) - Detailed analysis
- [Recommended Configuration](docker/starr/docker-compose.yml.recommended) - Production-ready config
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [LinuxServer.io Documentation](https://docs.linuxserver.io/)

## ✅ Success Criteria

Migration is successful when:

- [ ] All services running as non-root user
- [ ] All services accessible and functional
- [ ] Health checks passing
- [ ] No security vulnerabilities (PUID/PGID not 0)
- [ ] Port conflicts resolved
- [ ] Resource limits configured
- [ ] Monitoring and logging working

---

**Migration Time Estimate**: 15-30 minutes
**Difficulty**: Medium
**Risk Level**: Low (with proper backups)

