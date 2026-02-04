# qBittorrent Performance Troubleshooting Guide

## 🎯 Issue: qBittorrent Downloads Extremely Slow

**Date**: $(date)  
**Server**: mediaserver (192.168.1.11)  
**Status**: Investigating slow download speeds

---

## 🔍 Quick Diagnostic Commands

Run these commands on your media server (`mediaserver`) to diagnose the issue:

### 1. Check Container Status
```bash
# Check if containers are running
docker ps | grep -E "(qbittorrent|gluetun)"

# Check container logs
docker logs qbittorrent --tail 20
docker logs gluetun --tail 20
```

### 2. Check VPN Connection
```bash
# Test VPN connectivity
docker exec gluetun ping -c 3 8.8.8.8

# Check VPN status endpoint
docker exec gluetun curl -s http://localhost:8000/v1/publicip/ip
```

### 3. Check Network Configuration
```bash
# Check network interfaces
ip addr show

# Check routing
ip route show

# Test connectivity
ping -c 3 192.168.1.1
ping -c 3 8.8.8.8
```

### 4. Check qBittorrent Settings
Access qBittorrent WebUI at: `http://192.168.1.11:8080`

**Check these critical settings:**

#### Speed Tab:
- [ ] Global Rate Limits: Download: **Unlimited** (0)
- [ ] Global Rate Limits: Upload: **Unlimited** (0)
- [ ] Alternative Speed Limits: **Disabled**

#### Connection Tab:
- [ ] Listening Port: **Auto** (or 6881-6889)
- [ ] UPnP / NAT-PMP: **Enabled** (for VPN port forwarding)
- [ ] Use UPnP / NAT-PMP port forwarding from my router: **Enabled**

#### BitTorrent Tab:
- [ ] Protocol: **Both TCP and μTP** (try TCP only if VPN issues)
- [ ] Global maximum number of connections: **500**
- [ ] Maximum number of upload slots: **20**
- [ ] Maximum number of connections per torrent: **100**
- [ ] Maximum number of upload slots per torrent: **4**

---

## 🔧 Most Likely Causes & Fixes

### 1. **VPN Server Congestion** (Most Common)
**Symptoms**: Slow downloads, high latency
**Fix**:
```bash
# Change VPN server location in docker-compose.yml
# Try different PIA regions: US East, US West, Canada, Netherlands
# Restart containers after change
docker-compose down
docker-compose up -d
```

### 2. **qBittorrent Settings Misconfigured**
**Symptoms**: Settings not optimized for VPN
**Fix**: Use settings above, especially TCP-only protocol

### 3. **Port Forwarding Issues**
**Symptoms**: Few or no peers connecting
**Check**:
```bash
# Check if ports are open
docker exec gluetun curl -s http://localhost:8000/v1/openvpn/portforwarded

# Test port forwarding manually
telnet 192.168.1.11 8080  # qBittorrent port
```

### 4. **Container Resource Limits**
**Symptoms**: CPU/Memory constrained
**Check**:
```bash
# Check resource usage
docker stats qbittorrent

# Check limits in docker-compose.yml
# CPU limit: 2.0 cores (should be sufficient)
# Memory limit: 4G (should be sufficient)
```

### 5. **Disk I/O Bottleneck**
**Symptoms**: Downloads start fast then slow down
**Check**:
```bash
# Test disk speed
dd if=/dev/zero of=/tmp/test bs=1M count=100

# Check mount points
df -h /data/media/downloads
df -h /external/media/torrents
```

---

## 🧪 Testing Steps

### Step 1: Test Without VPN
**Temporarily disable VPN to isolate the issue:**
```bash
# Stop containers
docker-compose down

# Edit docker-compose.yml - comment out network_mode for qbittorrent
# Change: network_mode: "service:gluetun"
# To: # network_mode: "service:gluetun"

# Start qbittorrent directly (non-VPN)
docker-compose up -d qbittorrent

# Test download speed
# If faster without VPN → VPN/server congestion issue
# If still slow → Different problem (settings, ports, etc.)
```

### Step 2: Test Small Torrent
**Download a small, healthy torrent:**
```bash
# Find a small Linux ISO torrent with many seeders
# Ubuntu ISO (~1GB) is good test
# Monitor connection count in qBittorrent WebUI
# Should see 50+ connections quickly
```

### Step 3: Monitor Network
**Check for network-level issues:**
```bash
# Monitor network traffic
iftop -i eth0  # or whatever interface name

# Check for dropped packets
ping -c 100 8.8.8.8 | grep "packet loss"
```

---

## 🎯 Quick Fixes to Try First

### 1. **Restart VPN Container**
```bash
docker-compose restart gluetun
docker-compose restart qbittorrent
```

### 2. **Change VPN Server**
Edit `docker-compose.yml`:
```yaml
environment:
  - SERVER_REGIONS=US West  # Try different region
```

### 3. **Optimize qBittorrent Settings**
- Enable **encryption: Require encryption**
- Set **protocol to TCP only** (VPN compatibility)
- Reduce **global connections to 200** (VPN bandwidth)
- Enable **alternative speed limits OFF**

### 4. **Check Torrent Health**
- Ensure torrents have **50+ seeders**
- Check **torrent age** (fresh torrents perform better)
- Try **magnet links vs .torrent files**

### 5. **ISP Throttling Test**
Some ISPs throttle torrent ports. Test by:
```bash
# Change listening port to something else (like 55555)
# In qBittorrent: Settings → Connection → Listening Port
```

---

## 📊 Expected Performance

**With Good Setup:**
- **Connection Count**: 50-200 peers per torrent
- **Download Speed**: 5-20 MB/s (depending on your internet)
- **Ping to Peers**: <200ms average
- **Disk I/O**: >50 MB/s write speed

**VPN Impact:**
- Speed reduction: 10-30% (normal)
- Connection count: 20-50% reduction (normal)
- If speed <1 MB/s → Configuration issue
- If 0 connections → Port/VPN/firewall issue

---

## 🚨 Emergency Fix: Direct Connection (Test Only)

**⚠️ WARNING**: This bypasses VPN - use only for testing!

```bash
# Temporarily run qBittorrent without VPN
docker-compose down
docker-compose up -d qbittorrent  # Will use direct internet

# Test download speed
# Monitor performance vs VPN

# Restore VPN when done testing
docker-compose up -d gluetun
docker-compose restart qbittorrent
```

---

## 📋 Run Results & Analysis

**Please run the diagnostic commands above and share the results:**

1. `docker ps` output
2. `docker logs qbittorrent --tail 10`
3. VPN connectivity test
4. qBittorrent WebUI screenshots
5. Speed test results

**Most likely cause**: VPN server congestion or qBittorrent settings not optimized for VPN traffic.

**Next step**: Try changing VPN server region first - that's the quickest fix for most "slow torrent" issues.
