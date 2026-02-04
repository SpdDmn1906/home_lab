# Service Optimization Recommendations

**Date**: 2025-12-29
**Server**: mediaserver (192.168.1.11)
**Purpose**: Performance optimizations for Plex and STARR stack based on audit findings

---

## 🎬 Plex Media Server Optimization

### Current Configuration Analysis

**Current State:**
- Custom Dockerfile build (`my-plex-image`)
- Memory limit: 4GB (currently using 1.3GB - 32%)
- CPU: Intel i5-4690K (3 cores, hardware transcoding capable via Quick Sync)
- **No GPU**: CPU-based transcoding only
- Network: Host mode (correct for Plex)
- Storage: NAS at 100% capacity (critical issue - blocks 4K transcoding)

**4K Goals:**
- ✅ Multiple 4K streams locally (via direct play)
- ⚠️ HEVC/x265 compatibility issues (requires "Force Direct Play")
- ✅ External 1080p streaming (need QoS/limits)
- ⚠️ Zero interference between local and external

### Optimization Recommendations

#### 0. **Reliability First: Avoid Shared USB Hub Between NIC + Media Drive (NEW)**

During live troubleshooting, we identified a high-impact reliability risk:

- The server’s **USB Ethernet** and **USB external media drive** were on the **same USB hub/root path**.
- This can create micro-stalls that manifest as **Direct Play “freezing”** even at low bitrates.

**Recommendation (low-cost):**
- Prefer the **onboard NIC** for Plex traffic (gigabit is sufficient for local 4K direct play).
- If you need faster-than-1GbE later, prefer **PCIe 2.5GbE** (avoid sharing a USB controller with storage).

Details: [PLEX_PLAYBACK_FREEZING_INVESTIGATION.md](PLEX_PLAYBACK_FREEZING_INVESTIGATION.md)

#### 1. **Memory Optimization (Critical for 4K)**

**Current:** 4GB limit (32% usage)
**Recommended:** 8-12GB for 4K and multiple streams

```yaml
# In Docker compose or run command
deploy:
  resources:
    limits:
      memory: 12G  # Increased for 4K transcoding buffers
    reservations:
      memory: 4G   # Increased reservation
```

**Why:**
- **4K transcoding requires large buffers** (50-100GB disk, 4-8GB RAM)
- Multiple concurrent streams require more RAM
- Metadata database for large libraries benefits from more memory
- **Direct play uses less RAM than transcoding** (encourage direct play)

#### 2. **Hardware Transcoding Optimization (Quick Sync)**

**Current:** `/dev/dri` mounted (good!)
**No GPU**: Using Intel Quick Sync (CPU integrated graphics)

```yaml
# Add to Plex container
devices:
  - /dev/dri:/dev/dri  # Intel Quick Sync for hardware transcoding
environment:
  - PLEX_PLATFORM=linux
  - PLEX_ARCH=x86_64
  # Quick Sync environment (if needed)
  - VAAPI_DEVICE=/dev/dri/renderD128
```

**Hardware Transcoding Settings (in Plex UI):**
1. Settings → Transcoder
2. ✅ Enable "Use hardware acceleration when available" (**Critical for 4K**)
3. ✅ Enable "Use hardware-accelerated video encoding"
4. **For 4K**: Set "Transcoder quality" to "Prefer higher speed encoding" (faster, not best quality)
5. Increase "Transcoder default throttle buffer" to **600 seconds** (critical for 4K)
6. **Limit concurrent transcodes**: Set to 4 (CPU limitation)

**Quick Sync Limitations:**
- ⚠️ Haswell (i5-4690K) Quick Sync has **limited 4K capability**
- ✅ Excellent for 1080p transcoding
- **Strategy**: Use for 1080p external streams, avoid for 4K if possible

#### 3. **Transcode Directory Optimization (Critical for 4K)**

**Current:** Using tmpfs (good!)
**4K Requirement:** 50-100GB for transcoding buffers (cannot use RAM entirely)

**Recommended (Hybrid Approach):**
```yaml
# In Docker compose
tmpfs:
  - /tmp:size=2G
  - /transcode_cache:size=8G  # RAM cache for active transcodes
volumes:
  - /mnt/transcode:/transcode  # Disk-based for 4K buffers (needs 100GB+ free)
environment:
  - PLEX_MEDIA_SERVER_TMPDIR=/transcode
```

**Alternative (If Storage Limited):**
```yaml
# Use tmpfs only (limited to available RAM)
tmpfs:
  - /tmp
  - /transcode:size=8G,noexec,nosuid,nodev  # Max RAM available
environment:
  - PLEX_MEDIA_SERVER_TMPDIR=/transcode
```

**Why:**
- **4K transcoding needs 50-100GB buffers** (too large for RAM)
- Use disk-based transcode directory on fast storage (SSD preferred)
- Use RAM cache for active transcodes (smaller buffers)
- **Storage blocker**: Must free up 100GB+ for 4K transcoding

#### 4. **Network Optimization (Critical for 4K & External Streaming)**

**Current:** Host network (correct)
**4K & External Streaming Requirements:**

```yaml
# Ensure proper network settings
network_mode: host
environment:
  - PLEX_UID=1000
  - PLEX_GID=1004
  - ADVERTISE_IP=http://192.168.1.11:32400/
  - PLEX_CLAIM=${PLEX_CLAIM}
```

**Plex Settings (Critical for 4K Goals):**

1. **Settings → Network:**
   - ✅ Enable "Enable remote access"
   - ✅ **Enable "Treat WAN IP as LAN bandwidth"** (Fortress mode)
   - ✅ Set "LAN Networks": `192.168.1.0/24`
   - Set "Manual port" to 32400
   - Set "Internet upload speed": **35 Mbps** (Xfinity typical)
   - ✅ Set "Custom server access URLs": `http://192.168.1.11:32400`

2. **Settings → Remote Access:**
   - Set "Limit remote stream bitrate": **10 Mbps** (1080p max)
   - This enforces external quality limits automatically

3. **Per-User Settings (External Users):**
   - Set "Remote streaming quality": Maximum 1080p (10 Mbps)
   - This prevents interference with local 4K

**Router QoS Configuration (Asus Nighthawk):**
- **Priority 1 (Highest)**: Plex server (192.168.1.11) + Local streaming devices
- **Priority 2 (High)**: Other local devices
- **Priority 3 (Medium)**: External Plex streams
- **Priority 4 (Low)**: Downloads (STARR stack)

**Bandwidth Limits:**
- External upload cap: 30 Mbps (reserve 10 Mbps for other)
- Per external stream: 10 Mbps max
- Local: Unlimited (gigabit LAN sufficient)

#### 5. **Media Library Optimization (Critical for 4K)**

**Storage Issue (Critical - Blocks 4K):**
- NAS at 100% capacity (28GB free)
- External drive at 98% capacity (64GB free)
- **4K transcoding requires 100GB+ free** (cannot transcode without buffers)

**Immediate Actions (Priority):**
```bash
# Find large files to clean
find /data/media -type f -size +10G -ls | sort -k7 -rn | head -20

# Check for duplicates
fdupes -r /data/media > /tmp/duplicates.txt

# Remove old completed downloads
find /data/media/downloads -type f -mtime +30 -ls

# Find and remove transcoding temp files
find /transcode -type f -mtime +1 -delete  # If using disk-based transcode
```

**4K-Specific Actions:**
1. **Free up 100GB+ on NAS** → Critical for 4K transcoding buffers
2. **Create dedicated transcode directory** → On fastest storage (SSD if possible)
3. **Archive old 4K content** → Move rarely watched 4K files to slower storage
4. **Pre-transcode HEVC to x264** → Reduces need for transcoding (if client compatibility issue)

**Long-term:**
- Expand NAS storage (add drives or upgrade)
- Implement automated media cleanup
- Archive old/rarely accessed content
- Consider separate storage for 4K content

#### 6. **Database Optimization**

**Plex Settings:**
- Settings → Library
- ✅ Enable "Generate video preview thumbnails" (if desired)
- Set "Scanner" to "Plex Series Scanner" for TV, "Plex Movie Scanner" for Movies
- Enable "Detect theme music"
- Set "Scanner thread priority" to "Higher"

**Maintenance:**
```bash
# Optimize Plex database (via Plex UI)
# Settings → Troubleshooting → Optimize Database

# Or manually (backup first!)
docker exec plex /usr/lib/plexmediaserver/Plex\ Media\ Server --sqlite /config/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db "VACUUM;"
```

#### 7. **Complete Optimized Plex Configuration (4K-Ready)**

```yaml
plex:
  image: plexinc/pms-docker:latest  # Use official instead of custom
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
    - /mnt/transcode:/transcode  # Disk-based for 4K buffers (100GB+ free required)
  devices:
    - /dev/dri:/dev/dri  # Intel Quick Sync for hardware transcoding
  tmpfs:
    - /tmp:size=2G,noexec,nosuid,nodev
  deploy:
    resources:
      limits:
        cpus: '3.0'  # Use all 3 cores (for transcoding if needed)
        memory: 12G  # Increased for 4K transcoding buffers
      reservations:
        cpus: '0.5'
        memory: 4G   # Increased reservation
  healthcheck:
    test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:32400/web"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
```

**4K-Specific Plex Settings (Web UI):**
- Settings → Transcoder → Enable hardware acceleration
- Settings → Transcoder → Transcoding buffer: 600 seconds
- Settings → Transcoder → Maximum simultaneous transcodes: 4
- Settings → Network → LAN Networks: `192.168.1.0/24`
- Settings → Network → Treat WAN IP as LAN bandwidth: ✅ Enabled
- Settings → Remote Access → Internet upload speed: 35 Mbps
- Settings → Remote Access → Limit remote stream bitrate: 10 Mbps (1080p max)

---

## 📥 STARR Stack Optimization

### Current Configuration Analysis

**Current State:**
- All services running as root (CRITICAL - fix first!)
- No resource limits
- No health checks
- Timezone inconsistency (Sonarr uses UTC)
- Good VPN integration via Gluetun

### Optimization Recommendations

#### 1. **Fix Root Access (Priority #1)**

**Current:** PUID=0, PGID=0
**Recommended:** PUID=1000, PGID=1004

```yaml
# For all STARR services
environment:
  - PUID=1000
  - PGID=1004
  - TZ=America/New_York  # Standardize timezone
```

**See:** [IMMEDIATE_ACTION_PLAN.md](IMMEDIATE_ACTION_PLAN.md) Fix #1

#### 2. **Resource Limits**

**Recommended Limits:**

```yaml
# qBittorrent (active downloading)
deploy:
  resources:
    limits:
      cpus: '2.0'  # High CPU for downloads
      memory: 4G   # More memory for large torrents
    reservations:
      cpus: '0.5'
      memory: 512M

# Radarr/Sonarr (moderate CPU)
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 2G
    reservations:
      cpus: '0.25'
      memory: 256M

# Indexers (low CPU)
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 1G
    reservations:
      cpus: '0.1'
      memory: 128M
```

#### 3. **qBittorrent Optimization**

**Container Settings:**
- Use Gluetun network (already configured ✅)
- Add resource limits (above)

**qBittorrent WebUI Settings:**
1. **Connection:**
   - Max connections per torrent: 200
   - Max uploads per torrent: 4
   - Max connections global: 500
   - Max uploads global: 10

2. **Speed:**
   - Upload limit: Set based on your upload speed
   - Download limit: Unlimited (or set if needed)

3. **Advanced:**
   - Disk cache: 128MB (increase if you have RAM)
   - Disk cache expiry: 60 seconds
   - Enable OS cache: ✅
   - Pre-allocate all files: ✅ (prevents fragmentation)

4. **Performance:**
   - Coalesce read & write: ✅
   - Piece extents: ✅

#### 4. **Radarr/Sonarr Optimization**

**Container Settings:**
```yaml
environment:
  - PUID=1000
  - PGID=1004
  - TZ=America/New_York
  - UMASK=002  # Better file permissions
```

**Radarr Settings (via WebUI):**
1. **Media Management:**
   - ✅ Rename files
   - ✅ Download propers & repacks
   - ✅ Create empty movie folders
   - ✅ Delete empty folders
   - Set "Change File Date" to "Release Date"

2. **Quality Profiles:**
   - Optimize for your storage capacity
   - Consider HEVC/H.265 for space savings

3. **Indexers:**
  - Use Prowlarr (Jackett generally not needed)
   - Enable RSS sync: Every 15 minutes
   - Enable automatic search: ✅

**Sonarr Settings (via WebUI):**
1. **Media Management:**
   - ✅ Rename files
   - ✅ Download propers & repacks
   - ✅ Create empty series folders
   - ✅ Delete empty folders
   - Set "Change File Date" to "Air Date"

2. **Profiles:**
   - Set cutoff for your quality preferences
   - Enable upgrades if desired

#### 5. **Health Checks**

```yaml
# qBittorrent
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/api/v2/app/version"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s

# Radarr
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:7878/api/v3/system/status"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s

# Sonarr
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8989/api/v3/system/status"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

#### 6. **Storage Path Optimization**

**Current Issues:**
- Downloads on NAS (slow, 100% full)
- External drive at 98% capacity

**Recommended:**
```yaml
# Move downloads to faster local storage or external drive
volumes:
  # Downloads on external drive (faster, more space)
  - /external/media/downloads:/downloads  # Instead of /data/media/downloads
  # Final library on NAS
  - /data/media/Movies:/Movies
  - /data/media/TV Shows:/TV Shows
```

**Why:**
- Downloads happen frequently (needs speed)
- Library is accessed less frequently (NAS OK)
- External drive has more space (98% vs 100%)

#### 7. **Network Optimization**

**Already Excellent:**
- ✅ Using Gluetun VPN
- ✅ All traffic routed through VPN
- ✅ Kill switch enabled

**Additional:**
- Monitor VPN connection health
- Consider VPN region selection for speed
- Monitor bandwidth usage

#### 8. **Complete Optimized STARR Stack Configuration**

See: [docs/starr-stack-analysis.md](docs/starr-stack-analysis.md) for complete configuration

---

## 📊 Performance Monitoring

### Metrics to Monitor

**Plex:**
- Transcoding performance (CPU usage during transcode)
- Buffer health (check Grafana dashboards)
- Concurrent stream count
- Library scan performance

**STARR Stack:**
- Download speeds (qBittorrent)
- RSS sync times (Radarr/Sonarr)
- Disk I/O during downloads
- VPN connection stability

### Grafana Dashboards

**Recommended:**
- Plex Dashboard (if available)
- Docker Container metrics
- System resource usage
- Network performance

---

## 🎯 Priority Implementation Order

### Immediate (This Week)

1. ✅ Fix root access (security)
2. ✅ Fix storage capacity (critical)
3. ✅ Add resource limits
4. ✅ Standardize timezone

### Short-term (Next 2 Weeks)

5. ⚠️ Optimize Plex memory/CPU
6. ⚠️ Implement health checks
7. ⚠️ Optimize download paths
8. ⚠️ Tune qBittorrent settings

### Long-term (This Month)

9. 📋 Move to official Plex image
10. 📋 Database optimization
11. 📋 Automated cleanup scripts
12. 📋 Performance baseline monitoring

---

**Next**: See comprehensive final review document.

