# Plex 4K & Fortress Mode Strategy

**Date**: 2025-12-29
**Server**: mediaserver (192.168.1.11)
**Goal**: 4K local playback + external 1080p streaming + complete local independence

---

## 🎯 Goals Overview

### 4K Local Performance Goals
- ✅ Play 4K content to **multiple local devices simultaneously**
- ✅ **Zero lag or buffering** for 4K playback
- ✅ Handle x265/HEVC files (currently requires "Force Direct Play")
- ✅ Support x264 files natively
- ⚠️ **No GPU** - CPU-based transcoding (Intel i5-4690K Haswell)

### External Streaming Goals
- ✅ Serve **up to 1080p** to external users
- ✅ **No lag or buffering** for external streams
- ✅ **Zero interference** with local 4K playback
- ✅ Multiple concurrent external streams (3-4 simultaneous)

### Fortress Mode Goals
- ✅ **Complete local operation** when internet is down
- ✅ Plex works locally without internet
- ✅ Security cameras accessible via local network
- ✅ All services continue functioning offline

---

## 🖥️ Hardware Analysis

### Current Hardware Constraints

**CPU**: Intel Core i5-4690K (Haswell, 3 cores @ 3.50GHz)
- ✅ Has Intel Quick Sync (Hardware transcoding)
- ⚠️ Limited 4K transcoding capability
- ✅ Can handle 1080p transcoding easily
- ✅ Multiple 1080p streams possible

**RAM**: 23.41 GB total
- ✅ Sufficient for multiple streams
- ✅ Can use RAM for transcoding buffers

**Network**: Gigabit LAN (192.168.1.0/24)
- ✅ 1 Gbps local network (125 MB/s)
- ✅ Can handle multiple 4K streams locally
- ⚠️ External upload: ~35-40 Mbps (Xfinity typical)
- ✅ Sufficient for 3-4 concurrent 1080p streams

### 2025-12-30 Reliability Finding: USB Topology Can Cause “Freezing”

Even when bandwidth is “enough,” playback can still stall due to physical topology:

- A media server using a **USB Ethernet adapter** and a **USB external media drive** on the **same USB hub/root path** can exhibit micro-stalls that look like buffering/freezing.
- Prefer the **onboard NIC** for Plex traffic, or separate the NIC and external drive onto different controllers.

Details and next actions: [PLEX_PLAYBACK_FREEZING_INVESTIGATION.md](PLEX_PLAYBACK_FREEZING_INVESTIGATION.md)

**Storage**:
- 🔴 NAS: 100% full (28GB free) - **CRITICAL BLOCKER**
- 🔴 External: 98% full (64GB free) - **CRITICAL BLOCKER**
- ⚠️ 4K transcoding requires 50-100GB free for buffers

---

## 🎬 4K Playback Strategy

### Challenge: No GPU + CPU Limitations

**Problem**: i5-4690K (Haswell) has limited 4K transcoding capability.

**Solution**: **Maximize Direct Play** - Avoid transcoding entirely.

### Strategy 1: Direct Play Everything (Primary)

**Goal**: Play 4K files directly without transcoding.

**Requirements:**
1. ✅ Clients must support 4K codecs natively
2. ✅ Network bandwidth sufficient (1 Gbps LAN OK)
3. ✅ Clients support x265/HEVC (your main challenge)

**x265/HEVC Issue Analysis:**

**Problem**: Files require "Force Direct Play"
- Indicates client codec compatibility issue
- Server tries to transcode, fails, falls back to direct play
- Causes delays, potential buffering

**Root Causes:**
1. **Client doesn't support HEVC** - Most common
2. **Audio codec incompatibility** - Secondary issue
3. **Container format** - Sometimes an issue

**Solutions:**

**Option A: Upgrade Clients (Best Long-term)**
- Use clients that support HEVC natively:
  - ✅ **NVIDIA Shield TV** (Best for Plex)
  - ✅ **Apple TV 4K** (Good HEVC support)
  - ✅ **Roku Ultra** (HEVC support)
  - ✅ Modern smart TVs (2020+)
  - ⚠️ Older devices may need upgrade

**Option B: Pre-transcode to x264 (Workaround)**
- Convert HEVC files to x264 for compatibility
- Use Radarr/Sonarr to prefer x264 releases
- Or batch convert existing library

**Option C: Optimize Plex Settings (Immediate)**
- Force direct play for local network
- Disable transcoding for local IPs
- Configure clients for direct play

### Strategy 2: Optimize for Minimal Transcoding

**When Transcoding is Necessary:**

**For Local 4K:**
- Should be rare (direct play preferred)
- If needed: Hardware transcoding via Quick Sync
- Limit to 1-2 concurrent 4K transcodes
- Use lower quality if transcoding required

**For External (1080p max):**
- Always transcoding (upload bandwidth limits)
- Multiple streams possible (CPU can handle)
- Limit quality to prevent interference

### Plex Configuration for 4K Direct Play

**Server Settings (Plex Web UI):**

1. **Settings → Network:**
   - ✅ Enable "Treat WAN IP as LAN bandwidth" (Fortress mode)
   - ✅ Set "LAN Networks": `192.168.1.0/24`
   - ✅ Set "Custom server access URLs": `http://192.168.1.11:32400`
   - ✅ Enable "Enable IPv6 support" (if needed)
   - ✅ Set "Secure connections": Preferred

2. **Settings → Transcoder:**
   - ✅ Enable "Use hardware acceleration when available"
   - ✅ Enable "Use hardware-accelerated video encoding"
   - ✅ Set "Transcoder quality": "Prefer higher speed encoding" (for transcoding)
   - ✅ Set "Transcoder default throttle buffer": 600 seconds
   - ✅ Set "Background transcoding x264 preset": "veryfast"
   - ✅ Set "Maximum simultaneous video transcode": 4

3. **Settings → Remote Access:**
   - ✅ Enable remote access
   - ✅ Set "Internet upload speed": 35 Mbps (or your actual upload)
   - ✅ Set "Limit remote stream bitrate": 10 Mbps (1080p max)

**Per-User Settings (For External Users):**

1. **Remote Quality Limits:**
   - Set "Remote streaming quality": Maximum 1080p (10 Mbps)
   - Set "Direct Play/Stream": Always allow

2. **Local Quality (Your Devices):**
   - Set "Remote streaming quality": Maximum (original)
   - Set "Direct Play/Stream": Always allow

### Network Optimization for 4K

**⚠️ CRITICAL: Eero Network Latency Issue**

**Current Status:**
- ✅ "SC Home" (Asus): Working perfectly - **USE FOR 4K**
- ⚠️ "SC Home_Ext" (Eero): High latency (34-35ms, spikes to 210ms) - **NOT SUITABLE FOR 4K**

**Immediate Action:**
- **All 4K streaming devices MUST use "SC Home" (Asus) network**
- Do NOT use "SC Home_Ext" (Eero) for 4K until latency fixed
- See: [EERO_LATENCY_FIX_GUIDE.md](EERO_LATENCY_FIX_GUIDE.md) for fix

**Router QoS Configuration (Asus Nighthawk):**

**Priority Levels:**
1. **Highest**: Plex server (192.168.1.11)
2. **High**: Local streaming devices on "SC Home" (TVs, etc.)
3. **Medium**: External Plex streams
4. **Low**: Downloads (STARR stack)

**QoS Settings:**
```
Device Priority:
- 192.168.1.11 (Plex Server): Highest
- Local streaming devices on "SC Home": High
- External users: Medium
- VPN/download devices: Low

Bandwidth Limits:
- External upload: 30 Mbps total (reserve 10 Mbps for other traffic)
- Per external stream: 10 Mbps max
- Local: Unlimited (gigabit LAN)

Network Assignment:
- 4K devices: "SC Home" (Asus) only
- IoT devices: "SC Home_Ext" (Eero) - until latency fixed
```

---

## 🌐 External Streaming Strategy

### Bandwidth Allocation

**Available Upload**: ~35-40 Mbps (Xfinity typical)

**Allocation:**
- **External Plex**: 30 Mbps (3-4 concurrent 1080p streams @ 10 Mbps each)
- **Reserve**: 10 Mbps (for other services, overhead)

**Per-Stream Limits:**
- Maximum quality: 1080p (10 Mbps)
- Preferred: 720p (4-6 Mbps) for better reliability

### Plex Remote Settings

**Server Configuration:**
```yaml
Remote access: Enabled
Internet upload speed: 35 Mbps
Limit remote stream bitrate: 10 Mbps (1080p)
```

**User Limits (Per External User):**
- Maximum remote quality: 1080p (10 Mbps)
- Direct play: Always allow (if possible)
- Transcode quality: High (if transcoding needed)

### Preventing Interference

**Key Principle**: Local traffic always takes priority.

**Implementation:**

1. **Router QoS** (Critical):
   - Prioritize local network traffic
   - Limit external upload bandwidth
   - Shape external Plex traffic

2. **Plex Quality Limits**:
   - Hard limit: 10 Mbps per external stream
   - Server-side transcoding (don't rely on client limits)
   - Total external bandwidth: 30 Mbps cap

3. **Transcoding Location**:
   - External streams always transcoded on server
   - Use hardware acceleration (Quick Sync)
   - Limit concurrent transcodes (4 max)

---

## 🏰 Fortress Mode Implementation

### Goal: Complete Local Independence

**Requirement**: Everything works when internet is down.

### Current Dependencies on Internet

1. **Plex**:
   - ⚠️ Requires internet for authentication (initial login)
   - ✅ Can work offline once authenticated (with settings)
   - ⚠️ Remote access requires internet

2. **Security Cameras**:
   - ✅ Nest: Can access via local network (if configured)
   - ✅ Eufy: Homebase is local hub (works offline)
   - ✅ Abode: Local hub, works offline

3. **STARR Stack**:
   - ⚠️ Downloads require internet
   - ✅ Services work offline for management

### Fortress Mode Configuration

#### 1. Plex Offline Configuration

**Enable Local Authentication:**

**Settings → Network:**
```yaml
Custom server access URLs:
  - http://192.168.1.11:32400
  - http://plex.homelab.local:32400
```

**Settings → Network → Advanced:**
```yaml
Treat WAN IP as LAN bandwidth: ✅ Enabled
List of IP addresses and networks that are allowed without auth: 192.168.1.0/24
```

**Alternative: Plex DLNA (Local Only)**
- Enable DLNA server (Settings → DLNA)
- Access via DLNA (no authentication needed)
- Works completely offline

#### 2. Local DNS Resolution

**Goal**: Access services by name, not IP.

**Options:**

**Option A: Router DNS (Simplest)**
- Configure Asus Nighthawk DNS
- Add static DNS entries:
  - `plex.homelab.local` → `192.168.1.11`
  - `radarr.homelab.local` → `192.168.1.11`
  - `sonarr.homelab.local` → `192.168.1.11`

**Option B: AdGuard Home + Unbound (Advanced)**
- Local DNS server
- Ad blocking bonus
- More control

**Option C: /etc/hosts (Per-Device)**
- Manual configuration
- Works but not scalable

**Recommendation**: Start with router DNS, upgrade to AdGuard Home + Unbound later.

#### 3. Security Camera Local Access

**Nest Cameras:**
- ✅ Accessible via local IP (if known)
- Configure router port forwarding for local access
- Use Nest app with local network connection

**Eufy Cameras:**
- ✅ Homebase is local hub
- ✅ Eufy app works on local network
- ✅ No internet required for local access

**Abode Security:**
- ✅ Local hub operation
- ✅ Abode app works on local network
- ✅ No internet required

**Configuration:**
```bash
# Document camera IPs
# Nest cameras: Check router DHCP leases
# Eufy: Homebase IP (typically 192.168.1.x)
# Abode: Hub IP (typically 192.168.1.x)

# Test local access:
ping <camera-ip>
# Access web interface if available
```

#### 4. Local Service Access Documentation

**Create Local Access Guide:**

```markdown
# Local Access Guide (Works Offline)

## Plex Media Server
- Local URL: http://192.168.1.11:32400
- Alternative: http://plex.homelab.local:32400
- DLNA: Available (check devices)

## STARR Stack
- Radarr: http://192.168.1.11:7878
- Sonarr: http://192.168.1.11:8989
- qBittorrent: http://192.168.1.11:8080

## Monitoring
- Grafana: http://192.168.1.11:3000
- Prometheus: http://192.168.1.11:9090

## Security Cameras
- Nest: Check router DHCP leases
- Eufy Homebase: 192.168.1.x
- Abode Hub: 192.168.1.x
```

#### 5. Testing Fortress Mode

**Disconnect Internet Test:**

```bash
# 1. Disconnect internet (unplug router WAN)
# 2. Wait 5 minutes (let services stabilize)
# 3. Test all services:

# Plex
curl http://192.168.1.11:32400/web
# Should load Plex web interface

# Security cameras
# Access via mobile app on local network
# Should connect without internet

# STARR stack
curl http://192.168.1.11:7878
# Should load Radarr

# 4. Verify no errors in logs
journalctl -u plex -n 50
docker logs plex --tail 50
```

---

## 📊 Performance Targets

### 4K Local Playback

**Target Metrics:**
- **Buffer health**: >95% (no buffering)
- **Startup time**: <3 seconds
- **Seek response**: <1 second
- **Concurrent streams**: 3-4 simultaneous 4K streams

**Monitoring:**
- Track buffer health in Grafana
- Monitor CPU usage during playback
- Watch for transcoding triggers

### External Streaming

**Target Metrics:**
- **Buffer health**: >90%
- **Startup time**: <5 seconds
- **Concurrent streams**: 3-4 simultaneous 1080p
- **No impact on local**: Zero degradation

**Monitoring:**
- Track external stream count
- Monitor upload bandwidth usage
- Watch CPU usage (transcoding)

---

## 🔧 Implementation Roadmap

### Phase 1: Storage & Foundation (Week 1)

**Critical Blockers:**
1. ✅ Free up storage (100GB+ for 4K buffers)
2. ✅ Fix security issues
3. ✅ Optimize CIFS mounts

### Phase 2: 4K Optimization (Week 2)

**Actions:**
1. ✅ Configure Plex for direct play preference
2. ✅ Set router QoS (prioritize local traffic)
3. ✅ Configure Plex remote limits (10 Mbps max)
4. ✅ Test 4K playback (multiple devices)
5. ✅ Address HEVC compatibility (client upgrade or pre-transcode)

### Phase 3: External Streaming (Week 2-3)

**Actions:**
1. ✅ Set bandwidth limits per user
2. ✅ Configure server-side transcoding limits
3. ✅ Test concurrent streams (local 4K + external 1080p)
4. ✅ Verify no interference

### Phase 4: Fortress Mode (Week 3-4)

**Actions:**
1. ✅ Configure local DNS (router or AdGuard Home + Unbound)
2. ✅ Enable Plex offline mode settings
3. ✅ Document camera local access
4. ✅ Test offline operation
5. ✅ Create local access guide

---

## 🎯 Optimization Checklist

### Plex Server Configuration

- [ ] Enable hardware acceleration (Quick Sync)
- [ ] Set "Treat WAN IP as LAN bandwidth"
- [ ] Configure LAN network: `192.168.1.0/24`
- [ ] Set remote quality limit: 10 Mbps (1080p)
- [ ] Set transcoder buffer: 600 seconds
- [ ] Limit concurrent transcodes: 4
- [ ] Enable direct play for local network

### Network Configuration

- [ ] Configure router QoS (prioritize local traffic)
- [ ] Set bandwidth limits (external: 30 Mbps)
- [ ] Enable port forwarding for Plex (external access)
- [ ] Configure local DNS entries
- [ ] Test QoS effectiveness

### Storage Management

- [ ] Free up 100GB+ on NAS (4K transcoding buffers)
- [ ] Free up 200GB+ on external drive
- [ ] Optimize CIFS mounts (performance)
- [ ] Verify transcoding directory has space

### Client Configuration

- [ ] Upgrade clients to HEVC-compatible devices (if needed)
- [ ] Configure clients for direct play (local)
- [ ] Set quality limits on external devices
- [ ] Test direct play with x265 files

### Fortress Mode

- [ ] Configure local DNS
- [ ] Enable Plex offline settings
- [ ] Document camera local access
- [ ] Create local access guide
- [ ] Test offline operation

---

## 📈 Expected Results

### 4K Performance

**Before:**
- ❌ HEVC files require "Force Direct Play"
- ⚠️ Potential buffering
- ⚠️ Limited concurrent streams

**After:**
- ✅ Direct play for all 4K content
- ✅ Zero buffering (sufficient bandwidth)
- ✅ 3-4 concurrent 4K streams possible
- ✅ HEVC compatibility resolved (client upgrade or pre-transcode)

### External Streaming

**Before:**
- ⚠️ No quality limits
- ⚠️ Potential interference with local
- ⚠️ Unpredictable bandwidth usage

**After:**
- ✅ Hard 10 Mbps limit (1080p max)
- ✅ Zero interference with local 4K
- ✅ 3-4 concurrent external streams
- ✅ Predictable bandwidth usage

### Fortress Mode

**Before:**
- ❌ Plex requires internet for auth
- ⚠️ Camera access unclear
- ❌ Services dependent on internet

**After:**
- ✅ Plex works offline (once configured)
- ✅ Cameras accessible locally
- ✅ All services work without internet
- ✅ Complete local independence

---

## 🔍 Troubleshooting

### 4K Playback Issues

**Problem**: Still buffering with 4K
- Check network speed: `iperf3 -c <server-ip>`
- Verify direct play (check Plex dashboard)
- Check storage I/O: `iostat -x 1`
- Verify QoS is prioritizing local traffic

**Problem**: HEVC files won't play
- Upgrade client to HEVC-compatible device
- Or pre-transcode to x264
- Or use "Force Direct Play" (workaround)

### External Streaming Issues

**Problem**: External streams interfering with local
- Verify QoS configuration
- Check bandwidth limits are enforced
- Reduce external quality limits
- Monitor upload bandwidth usage

**Problem**: External streams buffering
- Increase transcoder buffer
- Reduce quality (720p instead of 1080p)
- Check upload bandwidth availability
- Verify transcoding performance

### Fortress Mode Issues

**Problem**: Plex won't work offline
- Enable "Treat WAN IP as LAN bandwidth"
- Add local IPs to allowed networks
- Enable DLNA as backup
- Test with internet disconnected

**Problem**: Cameras not accessible
- Verify cameras on local network
- Check IP addresses in router
- Test ping to camera IPs
- Check firewall rules

---

## 📚 Related Documentation

- [SERVICE_OPTIMIZATION_RECOMMENDATIONS.md](SERVICE_OPTIMIZATION_RECOMMENDATIONS.md) - Plex optimization details
- [NETWORK_SERVICE_AND_CIFS_FIXES.md](NETWORK_SERVICE_AND_CIFS_FIXES.md) - Network configuration
- [COMPREHENSIVE_FINAL_REVIEW.md](COMPREHENSIVE_FINAL_REVIEW.md) - Overall strategy

---

**Status**: 📋 **IMPLEMENTATION READY**
**Priority**: High (after security/storage fixes)
**Timeline**: Weeks 2-4 (after Phase 1 stabilization)

