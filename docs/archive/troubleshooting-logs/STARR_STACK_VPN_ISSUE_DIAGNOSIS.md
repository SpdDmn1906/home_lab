# STARR Stack VPN Connection Issue - Diagnosis

## 🔴 Critical Issue Identified

Your STARR stack is **completely offline** because the Gluetun VPN container cannot establish a connection. This is blocking all internet access for Radarr, Sonarr, Prowlarr, qBittorrent, and FlareSolverr.

## 📊 Error Analysis

### Primary Issue: Gluetun VPN Connection Failures

**Error Pattern 1: DNS Permission Denied**
```
write udp 172.23.0.2:38628->1.1.1.1:53: write: operation not permitted
```
- **Meaning**: Gluetun cannot send UDP packets for DNS resolution
- **Cause**: Missing network permissions or firewall blocking

**Error Pattern 2: Health Check Timeouts**
```
healthcheck error: dialing: dial tcp4 104.16.132.229:443: i/o timeout
```
- **Meaning**: VPN tunnel is not establishing properly
- **Cause**: VPN connection failing before health check can succeed

**Error Pattern 3: Continuous Restart Loop**
- Gluetun restarts every 6-16 seconds due to failed health checks
- Each restart attempts a new VPN connection but fails

### Secondary Issue: All STARR Services Offline

**All services showing "Resource temporarily unavailable":**
- **Prowlarr**: Cannot reach `indexers.prowlarr.com`, `prowlarr.servarr.com`
- **Radarr**: Cannot reach `radarr.servarr.com`
- **Sonarr**: Cannot reach `services.sonarr.tv`
- **FlareSolverr**: DNS resolution failing (`ERR_NAME_NOT_RESOLVED`)

**Root Cause**: Since all services use `network_mode: "service:gluetun"`, they have no internet access when gluetun fails.

## 🔍 Likely Root Causes

### 1. **Missing Docker Capabilities** (Most Likely)
Gluetun requires specific capabilities to manage network interfaces:
- `NET_ADMIN` - Required for VPN tunnel management
- `NET_BIND_SERVICE` - Required for binding ports
- `SYS_MODULE` - May be needed for some VPN providers

**Check your docker-compose.yml:**
```yaml
gluetun:
  cap_add:
    - NET_ADMIN
    - NET_BIND_SERVICE
    - SYS_MODULE  # Make sure this is present
```

### 2. **Missing /dev/net/tun Device**
Gluetun needs access to the TUN device for VPN tunnels:
```yaml
gluetun:
  devices:
    - /dev/net/tun:/dev/net/tun
```

### 3. **VPN Credentials/Configuration Issues**
- Invalid PIA credentials
- Corrupted or missing `pia.ovpn` file
- Incorrect credentials file path or permissions

### 4. **Network/Firewall Blocking**
- Host firewall blocking UDP port 1197 (PIA OpenVPN)
- Docker network misconfiguration
- ISP blocking VPN connections

### 5. **Docker Network Mode Issues**
- Gluetun may need `network_mode: bridge` (not host mode)
- Check if other containers are interfering

## 🛠️ Immediate Fix Steps

### Step 1: Verify Gluetun Configuration

SSH into your server and check the docker-compose.yml:

```bash
cd ~/Docker/config/data_gluetun
cat docker-compose.yml | grep -A 20 "gluetun:"
```

**Required elements:**
- ✅ `cap_add` with `NET_ADMIN`, `NET_BIND_SERVICE`, `SYS_MODULE`
- ✅ `devices: - /dev/net/tun:/dev/net/tun`
- ✅ Valid VPN credentials file path
- ✅ Correct PIA configuration file

### Step 2: Check VPN Credentials

```bash
# Verify credentials file exists and has correct permissions
ls -la ~/Docker/config/data_gluetun/credentials.txt
# Should show: -rw------- (600 permissions)

# Verify PIA config file exists
ls -la ~/Docker/config/data_gluetun/pia.ovpn
```

### Step 3: Check Gluetun Logs (Detailed)

```bash
# Get detailed error messages
docker logs gluetun --tail 100

# Look for:
# - Authentication errors
# - Connection refused errors
# - Permission denied errors
# - DNS resolution failures
```

### Step 4: Test VPN Connection Manually

```bash
# Check if gluetun can reach PIA servers
docker exec gluetun ping -c 3 8.8.8.8

# Check DNS resolution
docker exec gluetun nslookup cloudflare.com

# Check VPN status
docker exec gluetun curl -s http://localhost:8000/v1/publicip/ip
```

### Step 5: Verify Docker Permissions

```bash
# Check if /dev/net/tun exists and is accessible
ls -la /dev/net/tun

# Should show: crw-rw-rw- 1 root root 10, 200

# If missing or wrong permissions:
sudo chmod 666 /dev/net/tun
```

### Step 6: Check Host Firewall

```bash
# Check if firewall is blocking VPN
sudo ufw status
sudo iptables -L -n | grep 1197

# If firewall is active, allow VPN:
sudo ufw allow 1197/udp
```

## 🔧 Recommended Fixes

### Fix 1: Update Docker Compose (If Missing Capabilities)

Ensure your gluetun service has all required capabilities:

```yaml
gluetun:
  image: qmcgaw/gluetun:latest
  container_name: gluetun
  restart: unless-stopped
  cap_add:
    - NET_ADMIN
    - NET_BIND_SERVICE
    - SYS_MODULE
  devices:
    - /dev/net/tun:/dev/net/tun
  # ... rest of config
```

### Fix 2: Verify VPN Credentials

```bash
# Check credentials file format (should be username on line 1, password on line 2)
cat ~/Docker/config/data_gluetun/credentials.txt

# Verify PIA config
head -20 ~/Docker/config/data_gluetun/pia.ovpn
```

### Fix 3: Restart Gluetun with Clean State

```bash
cd ~/Docker/config/data_gluetun

# Stop all services
docker-compose down

# Remove gluetun container (keeps volumes)
docker rm gluetun

# Start gluetun first, wait for connection
docker-compose up -d gluetun

# Monitor logs for successful connection
docker logs -f gluetun

# Once connected (look for "VPN connection successful"), start other services
docker-compose up -d
```

### Fix 4: Test Without VPN (Temporary Diagnostic)

To verify services work without VPN, temporarily comment out `network_mode: "service:gluetun"` in one service:

```yaml
# Temporarily test radarr without VPN
radarr:
  # network_mode: "service:gluetun"  # Comment this out
  ports:
    - "7878:7878"  # Add this
```

**⚠️ Only for testing! Re-enable VPN after diagnosis.**

## 📋 Diagnostic Checklist

Run these commands and note the results:

- [ ] `docker ps | grep gluetun` - Is gluetun running?
- [ ] `docker logs gluetun --tail 50` - What errors appear?
- [ ] `docker inspect gluetun | grep -A 5 CapAdd` - Are capabilities set?
- [ ] `ls -la /dev/net/tun` - Does TUN device exist?
- [ ] `cat ~/Docker/config/data_gluetun/credentials.txt` - Are credentials valid?
- [ ] `ls -la ~/Docker/config/data_gluetun/pia.ovpn` - Does config exist?
- [ ] `docker exec gluetun ping -c 3 8.8.8.8` - Can container ping internet?
- [ ] `sudo ufw status` - Is firewall blocking VPN?

## 🎯 Expected Resolution

Once gluetun successfully connects, you should see in logs:
```
INFO [openvpn] Initialization Sequence Completed
INFO [healthcheck] healthy
```

Then all STARR services should regain internet connectivity.

## 📞 Next Steps

1. **Immediate**: Run diagnostic commands above
2. **Short-term**: Fix gluetun configuration based on findings
3. **Long-term**: Consider adding health check monitoring/alerts

---

**Generated**: 2026-01-20
**Issue Severity**: 🔴 Critical - All services offline
**Estimated Fix Time**: 15-30 minutes
