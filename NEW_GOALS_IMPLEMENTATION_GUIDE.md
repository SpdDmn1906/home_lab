# New Goals Implementation Guide: 4K Plex & Fortress Mode

**Date**: 2025-12-29
**Purpose**: Step-by-step guide for implementing your new 4K and Fortress Mode goals

---

## 🎯 Your New Goals

### 1. 4K Local Playback
- Play 4K content to multiple local devices simultaneously
- Zero lag or buffering
- Handle x265/HEVC files (currently requires "Force Direct Play")
- Support x264 files natively

### 2. External 1080p Streaming
- Serve up to 1080p to external users
- No lag or buffering
- Zero interference with local 4K playback
- Multiple concurrent external streams (3-4)

### 3. Fortress Mode
- Complete local independence when internet is down
- Plex works locally without internet
- Security cameras accessible via local network
- All services continue functioning offline

---

## 🚧 Critical Blockers Identified

### Blocker #1: Storage Full (CRITICAL - Must Fix First)

**Problem:**
- NAS: 100% full (28GB free)
- External: 98% full (64GB free)
- **4K transcoding requires 100GB+ free** for buffers

**Impact:**
- Cannot transcode 4K without buffer space
- Direct play still works (preferred) but transcoding impossible
- Service failures imminent

**Solution:**
- Free up minimum 100GB on NAS (for transcoding buffers)
- Free up 200GB+ on external drive
- See: [COMPREHENSIVE_FINAL_REVIEW.md](COMPREHENSIVE_FINAL_REVIEW.md) - Priority #2

### Blocker #2: Hardware Limitations

**CPU**: i5-4690K (Haswell)
- ✅ Has Intel Quick Sync (hardware transcoding)
- ⚠️ Limited 4K transcoding capability
- ✅ Excellent for 1080p transcoding

**Strategy:**
- **Maximize Direct Play** - Avoid transcoding 4K entirely
- Use transcoding only for external 1080p streams
- Consider hardware upgrade if direct play insufficient

### Blocker #3: HEVC/x265 Compatibility

**Problem:**
- Files require "Force Direct Play"
- Indicates client codec incompatibility
- Server tries to transcode, fails, falls back

**Solutions:**
1. **Upgrade Clients** (Best long-term)
   - NVIDIA Shield TV (Best for Plex)
   - Apple TV 4K
   - Modern smart TVs (2020+)

2. **Pre-transcode to x264** (Workaround)
   - Convert existing HEVC library
   - Configure Radarr/Sonarr to prefer x264 releases

3. **Force Direct Play** (Temporary)
   - Configure Plex to always direct play locally
   - Accept limitation

---

## 📋 Implementation Roadmap (Source of Truth)

This guide intentionally **does not duplicate** the full project roadmap anymore.

- **Primary roadmap**: [COMPREHENSIVE_FINAL_REVIEW.md](COMPREHENSIVE_FINAL_REVIEW.md) (kept current)
- **New high-impact Plex finding**: [PLEX_PLAYBACK_FREEZING_INVESTIGATION.md](PLEX_PLAYBACK_FREEZING_INVESTIGATION.md)

Use the sections below as a **tactical execution checklist**, not the canonical timeline.

### Phase 1: Foundation (Execution Checklist)

**Must Complete Before 4K Goals:**

1. **Fix Security** (Day 1-2)
   - Fix STARR stack root access
   - Fix Node Exporter
   - Change Grafana password
   - **Time**: 3-4 hours
   - **See**: [IMMEDIATE_ACTION_PLAN.md](IMMEDIATE_ACTION_PLAN.md)

2. **Free Up Storage** (Day 3-4) - **CRITICAL FOR 4K**
   - Audit and clean large files
   - Remove old downloads
   - Find and remove duplicates
   - **Target**: 100GB+ free on NAS, 200GB+ on external
   - **Time**: 4-6 hours
   - **Impact**: Enables 4K transcoding buffers

3. **Fix Network/Mounts** (Day 5)
   - Update fstab with optimized CIFS mounts
   - Fix boot errors
   - **Time**: 1-2 hours

---

### Phase 2: 4K Optimization (Execution Checklist)

**Goal:** Enable smooth 4K local playback

**⚠️ Important Network Reality Check**

The Eero wireless satellite backhaul can cause jitter and stalls, but recent testing also showed **server USB topology and client behavior** can cause freezes even on `SC Home`.

Before blaming the mesh:
- Validate server stability (NIC + USB topology): [PLEX_PLAYBACK_FREEZING_INVESTIGATION.md](PLEX_PLAYBACK_FREEZING_INVESTIGATION.md)
- Then tune/upgrade `SC Home_Ext` as needed: [EERO_LATENCY_FIX_GUIDE.md](EERO_LATENCY_FIX_GUIDE.md)
- 🔴 Eero network NOT suitable for 4K until latency fixed
- See: [EERO_LATENCY_FIX_GUIDE.md](EERO_LATENCY_FIX_GUIDE.md) - Fix first (30 min)

**Day 1-2: Plex Configuration**

1. **Configure for Direct Play:**
   ```bash
   # Plex Web UI → Settings → Network
   # ✅ Enable "Treat WAN IP as LAN bandwidth"
   # ✅ Set "LAN Networks": 192.168.1.0/24
   # ✅ Set "Custom server access URLs": http://192.168.1.11:32400
   ```

2. **Optimize Transcoding:**
   ```bash
   # Settings → Transcoder
   # ✅ Enable hardware acceleration (Quick Sync)
   # ✅ Set transcoder buffer: 600 seconds
   # ✅ Limit concurrent transcodes: 4
   ```

3. **Set Remote Limits:**
   ```bash
   # Settings → Remote Access
   # Set "Internet upload speed": 35 Mbps
   # Set "Limit remote stream bitrate": 10 Mbps (1080p max)
   ```

**Day 3: Router QoS Configuration**

1. **Configure Asus Nighthawk QoS:**
   - Priority 1: Plex server (192.168.1.11) + local streaming devices
   - Priority 2: Other local devices
   - Priority 3: External Plex streams
   - Priority 4: Downloads (STARR stack)

2. **Bandwidth Limits:**
   - External upload cap: 30 Mbps
   - Per external stream: 10 Mbps max
   - Local: Unlimited

**Day 4: Test 4K Performance**

1. Test single 4K stream (direct play)
2. Test multiple 4K streams (2-3 devices)
3. Test with external stream running (verify no interference)
4. Monitor buffer health and CPU usage

**Day 5: Address HEVC Issues**

**Option A: Client Upgrade** (Recommended)
- Research and purchase HEVC-compatible client
- NVIDIA Shield TV Pro recommended

**Option B: Pre-transcode** (Workaround)
- Identify HEVC files requiring "Force Direct Play"
- Batch convert to x264 (time-consuming)
- Or configure Radarr/Sonarr to prefer x264

---

### Phase 3: External Streaming (Week 2-3)

**Goal:** Reliable external 1080p streaming without interference

**Day 1: Configure Limits**

1. **Per-User Settings:**
   - Set maximum remote quality: 1080p (10 Mbps)
   - Enable direct play if possible (reduces transcoding)

2. **Server Settings:**
   - Enforce server-side limits (don't rely on client)
   - Monitor concurrent external streams

**Day 2: Test Concurrent Streams**

1. Start local 4K stream
2. Start external 1080p stream (test user)
3. Verify no interference
4. Monitor CPU, bandwidth, buffer health
5. Repeat with 2-3 external streams

**Day 3: Fine-tune QoS**

1. Adjust router QoS if needed
2. Verify bandwidth limits enforced
3. Test edge cases (4K + 4 external streams)

---

### Phase 4: Fortress Mode (Week 3-4)

**Goal:** Complete local independence

**Day 1: Local DNS**

**Option A: Router DNS (Simplest)**
```bash
# Asus Nighthawk Web UI → LAN → DHCP Server
# Add static DNS entries:
plex.homelab.local → 192.168.1.11
radarr.homelab.local → 192.168.1.11
sonarr.homelab.local → 192.168.1.11
grafana.homelab.local → 192.168.1.11
```

**Option B: AdGuard Home + Unbound (Advanced)**
- Install AdGuard Home + Unbound
- Configure router to use AdGuard as LAN DNS
- Add DNS rewrites for local services

**Day 2: Plex Offline Configuration**

1. **Enable Offline Settings:**
   ```bash
   # Plex Web UI → Settings → Network
   # ✅ Enable "Treat WAN IP as LAN bandwidth"
   # ✅ Set "List of IP addresses...allowed without auth": 192.168.1.0/24
   ```

2. **Enable DLNA (Backup):**
   ```bash
   # Settings → DLNA
   # ✅ Enable DLNA server
   # Works completely offline (no auth needed)
   ```

**Day 3: Camera Local Access**

1. **Document Camera IPs:**
   ```bash
   # Check router DHCP leases
   # Note: Nest, Eufy Homebase, Abode Hub IPs
   ```

2. **Test Local Access:**
   - Access cameras via mobile app on local network
   - Verify no internet required
   - Document access methods

**Day 4: Test Fortress Mode**

1. **Disconnect Internet:**
   ```bash
   # Unplug router WAN connection
   # Or disable WAN in router settings
   ```

2. **Test All Services:**
   - ✅ Plex: Access via http://192.168.1.11:32400
   - ✅ STARR Stack: Access via local IPs
   - ✅ Monitoring: Access Grafana/Prometheus
   - ✅ Cameras: Access via mobile app

3. **Verify No Errors:**
   ```bash
   docker logs plex --tail 50
   journalctl -u plex -n 50
   ```

4. **Document Results:**
   - What works offline
   - What requires internet
   - Any issues found

---

## 🔧 Configuration Examples

### Optimized Plex Container (4K-Ready)

```yaml
plex:
  image: plexinc/pms-docker:latest
  container_name: plex
  restart: unless-stopped
  network_mode: host
  environment:
    - PLEX_CLAIM=${PLEX_CLAIM}
    - PLEX_UID=1000
    - PLEX_GID=1004
    - TZ=America/New_York
    - ADVERTISE_IP=http://192.168.1.11:32400/
    - PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
    - PLEX_MEDIA_SERVER_MAX_STACK_SIZE=3000
    - PLEX_MEDIA_SERVER_MAX_LOCK_MEMORY=2000
    - PLEX_MEDIA_SERVER_TMPDIR=/transcode
  volumes:
    - /app/plex/config:/config
    - /data/media:/nas
    - /external:/external
    - /mnt/transcode:/transcode  # Disk-based for 4K buffers
  devices:
    - /dev/dri:/dev/dri  # Intel Quick Sync
  tmpfs:
    - /tmp:size=2G
  deploy:
    resources:
      limits:
        cpus: '3.0'
        memory: 12G  # Increased for 4K
      reservations:
        cpus: '0.5'
        memory: 4G
  healthcheck:
    test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:32400/web"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### Router QoS Configuration (Asus Nighthawk)

**Access**: Router Web UI → Adaptive QoS or Bandwidth Control

**Settings:**
```
Upload Bandwidth: 40 Mbps (your actual upload)
Download Bandwidth: 2000 Mbps (your download)

Device Priority:
- 192.168.1.11 (Plex Server): Highest
- Local streaming devices (TVs, etc.): High
- Other devices: Medium
- VPN/download devices: Low

Application Priority:
- Plex: Highest
- Video streaming: High
- Downloads: Low
```

---

## ✅ Success Criteria

### 4K Local Playback

- [ ] Can play 4K content to 3+ devices simultaneously
- [ ] Zero buffering or lag
- [ ] HEVC files play without "Force Direct Play" (or clients upgraded)
- [ ] Buffer health >95%
- [ ] Startup time <3 seconds

### External Streaming

- [ ] External users can stream up to 1080p
- [ ] No buffering for external streams
- [ ] 3-4 concurrent external streams possible
- [ ] Zero impact on local 4K playback
- [ ] Upload bandwidth capped at 30 Mbps

### Fortress Mode

- [ ] Plex accessible without internet
- [ ] Cameras accessible via local network
- [ ] All services work offline
- [ ] Local DNS resolution working
- [ ] Complete independence from internet

---

## 📊 Performance Monitoring

### Metrics to Track

**4K Performance:**
- Buffer health percentage
- Transcoding vs direct play ratio
- CPU usage during playback
- Network bandwidth usage
- Concurrent stream count

**External Streaming:**
- External stream count
- Upload bandwidth usage
- Transcoding performance
- Quality settings enforced

**Fortress Mode:**
- Offline operation success rate
- Local DNS resolution
- Service availability without internet

### Grafana Dashboards

Create dashboards for:
- Plex stream monitoring
- Bandwidth usage (local vs external)
- Transcoding performance
- Service availability

---

## 🆘 Troubleshooting

### 4K Still Buffering

**Check:**
1. Network speed: `iperf3 -c 192.168.1.11`
2. Direct play status (Plex dashboard)
3. Storage I/O: `iostat -x 1`
4. CPU usage: `htop`
5. QoS configuration

**Solutions:**
- Upgrade network if <100 Mbps
- Verify direct play (not transcoding)
- Check storage performance
- Reduce concurrent streams

### External Streams Interfering

**Check:**
1. QoS configuration
2. Bandwidth limits enforced
3. Upload bandwidth usage

**Solutions:**
- Strengthen QoS rules
- Reduce external quality limits
- Reduce concurrent external streams

### Fortress Mode Not Working

**Check:**
1. Plex offline settings
2. Local DNS resolution
3. Camera local access
4. Service dependencies

**Solutions:**
- Enable "Treat WAN IP as LAN bandwidth"
- Verify DNS entries
- Check camera IPs
- Test with internet disconnected

---

## 📚 Reference Documentation

- **[PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md](PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md)** - Complete strategy
- **[SERVICE_OPTIMIZATION_RECOMMENDATIONS.md](SERVICE_OPTIMIZATION_RECOMMENDATIONS.md)** - Detailed optimizations
- **[COMPREHENSIVE_FINAL_REVIEW.md](COMPREHENSIVE_FINAL_REVIEW.md)** - Overall roadmap

---

## 🎯 Priority Order

1. **Week 1**: Fix storage (critical blocker) + security fixes
2. **Week 2**: Configure 4K direct play + external limits + QoS
3. **Week 3**: Test 4K performance + configure fortress mode
4. **Week 4**: Fine-tune + address HEVC compatibility

**Total Estimated Time**: 20-30 hours over 4 weeks

---

**Status**: 📋 **READY FOR IMPLEMENTATION**
**Start With**: Fix storage (critical blocker) → Then proceed with Phase 2

