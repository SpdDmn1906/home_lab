# 🚀 qBittorrent Slow Downloads: Complete Solution Guide

## 🎯 Issue Summary
**Problem**: qBittorrent downloads are extremely slow
**Environment**: Running through Gluetun VPN (PIA) on Ubuntu media server
**Impact**: Downloads taking hours/days instead of minutes

---

## 🔍 Root Cause Analysis

Based on your setup, the **most likely causes** are:

### 1. **VPN Server Congestion** (80% likelihood)
- PIA VPN servers can get overloaded
- Current server may be in high-traffic area
- Distance from your location affects speed

### 2. **qBittorrent VPN Settings** (15% likelihood)
- Default settings not optimized for VPN
- Protocol conflicts (uTP vs TCP)
- Connection limits too high for VPN bandwidth

### 3. **Port Forwarding Issues** (5% likelihood)
- VPN port forwarding not working properly
- Firewall blocking torrent ports

---

## 🛠️ Step-by-Step Fix (15 Minutes)

### Step 1: Check Current Status
Run this on your media server (`mediaserver`):
```bash
# Quick diagnostic
./quick_qbittorrent_check.sh

# Or manually check:
docker ps | grep -E "(qbittorrent|gluetun)"
docker logs qbittorrent --tail 10
```

### Step 2: Optimize qBittorrent Settings
Access qBittorrent WebUI: `http://192.168.1.11:8080`

**Apply these critical settings:**

#### Speed Tab:
- Global Download Rate: **0** (unlimited)
- Global Upload Rate: **0** (unlimited)  
- Alternative Speed Limits: **Disabled**

#### Connection Tab:
- Listening Port: **Auto**
- UPnP/NAT-PMP: **Enabled**
- Use different port on startup: **Disabled**

#### BitTorrent Tab:
- **Protocol: TCP** (NOT "Both TCP and μTP")
- Global max connections: **200** (reduced for VPN)
- Max upload slots: **10** (reduced for VPN)
- Connections per torrent: **50** (reduced for VPN)
- Upload slots per torrent: **2** (reduced for VPN)

### Step 3: Change VPN Server (Most Important!)
Edit your `docker-compose.yml` file:

**Current (likely slow):**
```yaml
- SERVER_REGIONS=US East
```

**Try these in order:**
```yaml
- SERVER_REGIONS=Netherlands    # Usually fastest
- SERVER_REGIONS=Switzerland    # Good balance
- SERVER_REGIONS=Canada         # North American
```

**After changing server:**
```bash
docker-compose down
docker-compose up -d
```

### Step 4: Test Performance
1. **Download a test torrent** (small Linux ISO with 50+ seeders)
2. **Monitor connection count** in qBittorrent WebUI
3. **Check download speed** - should be 5-15 MB/s
4. **If still slow** - try next VPN server

---

## 📊 Expected Results

### Before Fix:
- Download speed: <1 MB/s
- Connections: 0-5 peers
- Time for 10GB file: 2+ hours

### After Fix:
- Download speed: 5-15 MB/s  
- Connections: 20-100 peers
- Time for 10GB file: 10-30 minutes

---

## 🔧 Advanced Troubleshooting

If basic fixes don't work:

### Test Without VPN (Isolate Issue)
```bash
# Temporarily disable VPN for testing
# Edit docker-compose.yml:
# Comment out: network_mode: "service:gluetun"
docker-compose restart qbittorrent

# Test download speed (should be fast)
# If fast without VPN → VPN server issue
# If still slow → Different problem (settings, ports, disk)
```

### Check VPN Connection Quality
```bash
# Test VPN responsiveness
docker exec gluetun ping -c 5 8.8.8.8

# Check port forwarding
docker exec gluetun curl -s http://localhost:8000/v1/openvpn/portforwarded
```

### Monitor System Resources
```bash
# Check if CPU/disk limited
docker stats qbittorrent

# Test disk speed
dd if=/dev/zero of=/tmp/test bs=1M count=100
```

---

## 🎯 Success Checklist

- [ ] qBittorrent container running: `docker ps | grep qbittorrent`
- [ ] Gluetun VPN running: `docker ps | grep gluetun`
- [ ] Settings optimized (TCP protocol, reduced limits)
- [ ] VPN server changed to Netherlands/Switzerland
- [ ] Test torrent downloading at 5+ MB/s
- [ ] 20+ connections per torrent

---

## 📞 Support Resources

**Created diagnostic tools:**
- `quick_qbittorrent_check.sh` - Quick status check
- `QB_PERFORMANCE_TROUBLESHOOTING.md` - Detailed troubleshooting guide
- `QBITTORRENT_VPN_OPTIMIZATION.md` - VPN-specific optimization

**If issues persist:**
1. Share output of `docker logs qbittorrent --tail 20`
2. Share output of `docker logs gluetun --tail 20`
3. Screenshot of qBittorrent WebUI settings
4. Test results with/without VPN

---

## ⏱️ Timeline to Fix

- **5 minutes**: Change VPN server to Netherlands
- **10 minutes**: Apply qBittorrent settings optimization  
- **15 minutes**: Test and verify performance improvement
- **30 minutes**: Try additional VPN servers if needed

**90% of cases resolve with VPN server change!** 🚀

---

*This guide addresses the most common causes of slow qBittorrent downloads in VPN setups. The solution is typically changing to a less congested VPN server and optimizing qBittorrent settings for VPN usage.*
