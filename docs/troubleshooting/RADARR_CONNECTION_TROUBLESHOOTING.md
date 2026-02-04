# Radarr Connection Issues: Troubleshooting Guide

## 🎯 Problem: Radarr Not Connecting Properly After Restart

**Symptoms:**
- Radarr web interface not loading
- Cannot access http://192.168.1.11:7878
- Radarr appears offline in docker ps
- Connection refused errors

---

## 🔍 Quick Diagnostic Steps

### Step 1: Check Container Status
```bash
# Check if Radarr is running
docker ps | grep radarr

# Check all STARR containers
docker ps | grep -E "(radarr|sonarr|prowlarr|qbittorrent|gluetun)"
```

### Step 2: Check Logs
```bash
# View recent Radarr logs
docker logs radarr --tail 20

# View VPN logs (critical for connection issues)
docker logs gluetun --tail 20

# Follow logs in real-time
docker logs -f radarr
```

### Step 3: Test Connectivity
```bash
# Test Radarr port
curl http://localhost:7878

# Test Radarr API
curl http://localhost:7878/api/v3/system/status

# Test VPN connectivity
docker exec gluetun ping -c 3 8.8.8.8
```

---

## 🚨 Most Common Causes & Fixes

### 1. **VPN Connection Failed** (Most Common - 60% of cases)

**Symptoms:** Radarr starts but cannot connect to indexers
**Error:** "Unable to connect to indexer" or "Network timeout"

**Fix:**
```bash
# Check VPN status
docker ps | grep gluetun

# Restart VPN if needed
docker-compose restart gluetun

# Wait 30 seconds, then restart Radarr
docker-compose restart radarr

# Verify VPN connection
docker exec gluetun curl -s http://localhost:8000/v1/publicip/ip
```

### 2. **Port Conflict** (20% of cases)

**Symptoms:** Port 7878 already in use by another service

**Check:**
```bash
# Check what's using port 7878
netstat -tulpn | grep :7878

# Alternative: use ss command
ss -tulpn | grep :7878
```

**Fix:**
```bash
# Change Radarr port in docker-compose.yml
environment:
  - PORT=7879  # Change from default 7878

# Or find conflicting service and stop it
# Then restart Radarr
docker-compose restart radarr
```

### 3. **Configuration Corruption** (10% of cases)

**Symptoms:** Radarr starts but web interface shows errors
**Logs show:** Database errors or config file issues

**Fix:**
```bash
# Backup config first
cp -r /home/youruser/Docker/radarr /home/youruser/Docker/radarr.backup

# Remove corrupted config (Radarr will recreate)
rm -rf /home/youruser/Docker/radarr/config.xml

# Restart Radarr
docker-compose restart radarr

# Reconfigure Radarr (you'll need to set it up again)
```

### 4. **Network Mode Issues** (5% of cases)

**Symptoms:** Radarr cannot reach internet despite VPN running

**Check:**
```bash
# Verify network mode
docker inspect radarr | grep -A 5 NetworkMode

# Should show: "NetworkMode": "service:gluetun"
```

**Fix:**
```yaml
# In docker-compose.yml, ensure:
services:
  radarr:
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
```

### 5. **Resource Constraints** (5% of cases)

**Symptoms:** Radarr starts but becomes unresponsive

**Check:**
```bash
# Check resource usage
docker stats radarr

# Check memory/CPU limits in docker-compose.yml
```

**Fix:**
```yaml
# Increase resource limits
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 2G
    reservations:
      cpus: '0.25'
      memory: 256M
```

---

## 🛠️ Quick Fix Commands

### Emergency Restart Sequence
```bash
# Stop all services
docker-compose down

# Start VPN first
docker-compose up -d gluetun

# Wait 30 seconds for VPN to connect
sleep 30

# Start Radarr
docker-compose up -d radarr

# Check logs
docker logs radarr --tail 10
```

### Force Clean Restart
```bash
# Stop and remove containers
docker-compose down

# Remove any orphaned containers
docker container prune -f

# Start fresh
docker-compose up -d

# Check status
docker ps
```

### Test Connectivity
```bash
# Test local access
curl -I http://localhost:7878

# Test from another machine on network
curl -I http://192.168.1.11:7878

# Test API
curl http://localhost:7878/api/v3/system/status
```

---

## 📊 Diagnostic Output Analysis

### Good Status (Working):
```
✅ Radarr container is RUNNING
✅ Gluetun VPN container is running
✅ Radarr port 7878 is accessible locally
✅ Radarr API is responding (HTTP 200)
```

### Problem Indicators:
```
❌ Radarr container is NOT running
❌ Gluetun VPN container is NOT running
❌ Radarr port 7878 is not accessible
❌ Radarr API not responding (HTTP 000)
```

### Log Error Patterns:

**VPN Issues:**
```
[gluetun] 2024/01/01 12:00:00 ERROR: Cannot connect to VPN server
```

**Port Conflicts:**
```
listen tcp :7878: bind: address already in use
```

**Config Issues:**
```
System.IO.IOException: The process cannot access the file 'config.xml'
```

**Network Issues:**
```
Unable to connect to remote server
Network is unreachable
```

---

## 🔧 Advanced Troubleshooting

### Check Mount Points
```bash
# Verify Docker can access directories
docker exec radarr ls -la /data/media
docker exec radarr ls -la /config

# Check permissions
docker exec radarr id  # Should show correct user ID
```

### DNS Resolution Test
```bash
# Test DNS from within container
docker exec radarr nslookup api.themoviedb.org

# Test internet connectivity
docker exec radarr ping -c 3 8.8.8.8
```

### Configuration Validation
```bash
# Check Radarr config file
cat /home/youruser/Docker/radarr/config.xml | head -20

# Verify key settings
grep -E "(Port|UrlBase|ApiKey)" /home/youruser/Docker/radarr/config.xml
```

---

## 📋 Recovery Checklist

- [ ] VPN (Gluetun) container is running
- [ ] Radarr container is running
- [ ] Port 7878 is not in use by another service
- [ ] Network mode is "service:gluetun"
- [ ] Config directory exists and is writable
- [ ] Media directories are mounted correctly
- [ ] No resource limits exceeded
- [ ] Web interface accessible at http://192.168.1.11:7878

---

## 🎯 Prevention Tips

### 1. **Monitor Regularly**
```bash
# Add to cron for daily checks
0 */6 * * * docker ps | grep -q radarr || echo "Radarr down" | mail -s "Radarr Alert" your@email.com
```

### 2. **Backup Configuration**
```bash
# Weekly backup
0 2 * * 1 cp -r /home/youruser/Docker/radarr /home/youruser/Docker/radarr.backup.$(date +%Y%m%d)
```

### 3. **Use Health Checks**
Ensure your docker-compose.yml has health checks:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:7878/api/v3/system/status"]
  interval: 30s
  timeout: 10s
  retries: 3
```

---

## 📞 When to Get Help

**Share these when asking for help:**
1. Output of: `docker ps`
2. Output of: `docker logs radarr --tail 50`
3. Output of: `docker logs gluetun --tail 20`
4. Your docker-compose.yml (relevant sections)
5. Network connectivity test results

**Most Radarr connection issues resolve with VPN restart + container restart!**
