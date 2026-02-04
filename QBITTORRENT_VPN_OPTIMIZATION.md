# qBittorrent VPN Optimization Guide

## 🎯 Problem: Slow Downloads Through VPN

**Common Issue**: qBittorrent downloads extremely slow when routed through VPN (like PIA + Gluetun)

**Root Causes**:
1. VPN server congestion/overloaded
2. qBittorrent settings not optimized for VPN
3. Protocol incompatibility (uTP vs TCP)
4. Port forwarding issues
5. ISP throttling torrent traffic

---

## 🏆 Best Settings for VPN Usage

### Connection Tab
```
Listening Port: Auto (let qBittorrent choose)
Use UPnP/NAT-PMP port forwarding: ✅ ENABLED
Use different port on each startup: ❌ DISABLED
```

### Speed Tab
```
Global Rate Limits:
  Download: 0 (unlimited)
  Upload: 0 (unlimited)
  
Alternative Speed Limits: ❌ DISABLED
```

### BitTorrent Tab
```
Protocol: TCP  ✅ (NOT "Both TCP and μTP")
Global maximum number of connections: 200  ⚠️ (reduced for VPN)
Global maximum number of upload slots: 10  ⚠️ (reduced for VPN)
Maximum number of connections per torrent: 50  ⚠️ (reduced for VPN)
Maximum number of upload slots per torrent: 2  ⚠️ (reduced for VPN)
```

### Advanced Tab
```
Network interface: Leave blank (auto)
Optional IP address to bind to: Leave blank
Disk write cache size: 64 MB
Disk read cache size: 64 MB
Enable OS cache: ✅ ENABLED
```

---

## 🌍 VPN Server Optimization

### Try Different PIA Regions (in order of recommendation):

1. **Netherlands** - Usually fastest for torrents
2. **Switzerland** - Good balance of speed/privacy
3. **Canada** - North American, good speeds
4. **US West** - If you're on West Coast
5. **US East** - If you're on East Coast

### Change VPN Server:
```yaml
# In docker-compose.yml, change this line:
  - SERVER_REGIONS=Netherlands  # Try different regions
```

### Test Server Load:
```bash
# Check VPN connection quality
docker exec gluetun curl -s http://localhost:8000/v1/openvpn/portforwarded
docker exec gluetun ping -c 5 8.8.8.8
```

---

## 🧪 Testing Methodology

### Step 1: Baseline Test (Without VPN)
```bash
# Temporarily disable VPN routing
# Edit docker-compose.yml:
# Comment out: network_mode: "service:gluetun"
# Restart qbittorrent
docker-compose restart qbittorrent

# Test download speed
# This gives you baseline (non-VPN) performance
```

### Step 2: VPN Test
```bash
# Restore VPN routing
# Uncomment: network_mode: "service:gluetun"
docker-compose restart qbittorrent

# Test same torrent
# Compare speeds - should be 70-90% of non-VPN speed
```

### Step 3: Server Hopping
```bash
# If VPN is slow, try different servers
# Change SERVER_REGIONS in docker-compose.yml
# Test speed after each change
```

---

## 🚨 Common Issues & Fixes

### Issue: 0 Connections
**Symptoms**: Torrent shows 0 peers, no download
**Fixes**:
1. Check if VPN is connected: `docker logs gluetun`
2. Verify port forwarding: Check Gluetun logs for port assignment
3. Try TCP-only protocol (not uTP)
4. Test without VPN temporarily

### Issue: Slow Start, Then Stops
**Symptoms**: Download starts fast, then slows to 0
**Fixes**:
1. Check disk space: `df -h /downloads`
2. Monitor disk I/O: `iotop` or `iostat`
3. Test different torrent (might be dead)
4. Check for disk throttling

### Issue: High CPU Usage
**Symptoms**: qBittorrent using 100% CPU
**Fixes**:
1. Reduce max connections (try 100 global)
2. Disable disk cache
3. Check for corrupted torrent files
4. Update qBittorrent version

---

## 📊 Performance Expectations

### Good Performance (VPN):
- **Download Speed**: 5-15 MB/s (depends on your internet)
- **Connections**: 20-100 per torrent
- **CPU Usage**: <50%
- **Memory Usage**: <500MB

### Poor Performance (Needs Fix):
- **Download Speed**: <1 MB/s
- **Connections**: <10 per torrent
- **Frequent disconnects**
- **High ping times**

---

## 🔧 Advanced Troubleshooting

### Check VPN Port Forwarding
```bash
# PIA assigns random port for forwarding
docker exec gluetun curl -s http://localhost:8000/v1/openvpn/portforwarded

# Set qBittorrent to use this port
# In WebUI: Settings → Connection → Listening Port
```

### Monitor Network Traffic
```bash
# Install tools
apt-get install nload iftop

# Monitor traffic
nload eth0  # or whatever interface
iftop -i eth0
```

### Debug qBittorrent
```bash
# Enable debug logging
# In WebUI: Settings → Behavior → Log file
# Set verbosity to "Debug"

# Check logs
docker logs qbittorrent --tail 50
```

---

## 🎯 Quick Action Plan

1. **Check current settings** in qBittorrent WebUI
2. **Apply the recommended settings** above
3. **Test download speed** with current VPN server
4. **Try different VPN servers** if slow
5. **Test without VPN** to establish baseline
6. **Check logs** if issues persist

**Most issues resolve with server change + TCP-only protocol!**
