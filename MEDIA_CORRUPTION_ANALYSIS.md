# Media File Corruption Analysis

**Date**: 2026-01-02
**Issue**: Random Plex playback freezing on specific files
**Root Cause**: H.264 NAL unit corruption in files downloaded during critical storage periods

---

## 🔍 Investigation Summary

### Problem Statement
User reported "heavy freezing" on specific media files (e.g., "Glory Road") that would play fine after re-downloading. The freezing occurred on multiple devices (Roku at 192.168.1.100, LG webOS TV at 192.168.1.19), ruling out client-specific issues.

### Initial Hypotheses (Ruled Out)
- ❌ Network latency/jitter
- ❌ Server CPU/RAM exhaustion
- ❌ Disk read speed issues
- ❌ Simple file truncation (file size was correct)
- ❌ Codec incompatibility (H.264 is universally supported)

### Root Cause: Internal Video Stream Corruption

Deep frame-by-frame validation using `ffmpeg` revealed **thousands of H.264 NAL (Network Abstraction Layer) unit errors** in the problematic file:

```
[h264 @ 0x5607158571c0] Invalid NAL unit size (0 > 11007).
[h264 @ 0x5607158571c0] Error splitting the input into NAL units.
[vist#0:0/h264 @ 0x5579ffe3f980] [dec:h264 @ 0x5579ffc7dd80] Error submitting packet to decoder: Invalid data found when processing input
```

**1,700+ errors** throughout the 2-hour file.

---

## 📊 Correlation: Low Storage Period

### Timeline of Critical Storage Events

| Date Range | Storage Status | Files Downloaded |
|------------|----------------|------------------|
| Dec 26-27, 2025 | `/external/media` at **98%** full | 9 files |
| Dec 28-31, 2025 | `/external/media` at **98-99%** full | 4 files |
| Jan 1-2, 2026 | `/external/media` at **98%** full, NAS at **100%** | 3 files (including Glory Road) |

### Why Low Storage Causes Corruption

1. **Incomplete Writes**: When storage is critically full, write operations may fail mid-stream without proper error handling by the torrent client or file system.
2. **Fragmentation**: Heavily fragmented free space can cause non-contiguous writes, leading to data corruption if the file system or application doesn't handle it properly.
3. **CIFS/SMB Issues**: Network file systems (like your `/external/media` CIFS mount) are especially vulnerable during low storage, as they may not properly report "disk full" errors to the client.
4. **qBittorrent Behavior**: qBittorrent may continue downloading pieces even when storage is critically low, resulting in partially written or corrupted video frames.

---

## 🔬 Technical Details: H.264 NAL Unit Corruption

### What are NAL Units?
H.264 video is structured as **Network Abstraction Layer (NAL) units** - self-contained packets of video data. Each NAL unit contains:
- A size header (how many bytes follow)
- The actual video data (I-frame, P-frame, B-frame, etc.)

### How Corruption Manifests
When a file is corrupted during download:
- **NAL unit size headers become invalid** (e.g., "size = 0" when data follows)
- **Video decoder cannot parse the stream** properly
- **Playback freezes** when the decoder hits a corrupt NAL unit
- **Simple clients (Roku, webOS) cannot recover** and stall indefinitely

### Why Basic Checks Don't Detect It
- **File size is correct**: The file was fully "written" (even if with corrupt data)
- **Sequential reads work**: `dd` and basic I/O don't validate H.264 structure
- **Container is valid**: The MP4 container (moov atom, etc.) is fine
- **Only frame-by-frame decode reveals it**: ffmpeg's `-v error -f null` test is required

---

## ✅ Validated Solution

### Detection Method
Run full frame decode validation:
```bash
docker run --rm -v /external/media:/media linuxserver/ffmpeg:latest \
  -v error -i "/media/path/to/file.mp4" -f null - 2>&1 | \
  grep -ciE "error|invalid|corrupt"
```

**Threshold**: > 10 errors = corrupted file (should be 0 for clean files)

### Remediation
1. **Delete the corrupted file**
2. **Re-download from the same or different source**
3. **Verify the new file** using the detection method above
4. **Ensure adequate free space** (> 10% free) before downloading

---

## 🛡️ Prevention Strategy

### 1. Storage Monitoring & Alerts
- **Target**: Keep `/external/media` < 90% full at all times
- **Alert threshold**: 85% full (warning), 90% full (critical)
- **Action**: Automated cleanup of completed torrents, old media, or expansion

### 2. qBittorrent Configuration
Add to qBittorrent settings:
```ini
[Preferences]
Downloads\PreAllocation=true  # Pre-allocate disk space
Downloads\DiskWriteCacheSize=64  # Increase write cache
Downloads\DiskWriteCacheTTL=60  # Cache TTL
```

**In qBittorrent UI**:
- Settings → Downloads → "Pre-allocate disk space for all files" = **Enabled**
- Settings → Advanced → "Disk cache" = **64 MB** (or higher)
- Settings → Downloads → "When seeding time reaches" = **Auto-remove** (to free space)

### 3. Automated Post-Download Validation
Create a Radarr/Sonarr custom script (`/config/scripts/validate_media.sh`):
```bash
#!/bin/bash
# Radarr/Sonarr post-import validation script

FILE="$radarr_moviefile_path"  # or $sonarr_episodefile_path

echo "Validating: $FILE"
errors=$(docker run --rm -v /external/media:/media linuxserver/ffmpeg:latest \
  -v error -i "/media${FILE#/external/media}" -f null - 2>&1 | \
  grep -ciE "error|invalid|corrupt")

if [ "$errors" -gt 10 ]; then
    echo "ERROR: File is corrupted ($errors errors). Marking for re-download."
    # Trigger Radarr/Sonarr to re-download
    exit 1
fi

echo "File validated successfully."
exit 0
```

### 4. CIFS Mount Optimization
Update `/etc/fstab` with strict error handling:
```
//nas/media /external/media cifs credentials=/root/.smbcredentials,iocharset=utf8,file_mode=0777,dir_mode=0777,noserverino,vers=3.0,_netdev,nofail,x-systemd.automount,x-systemd.requires=network-online.target,hard,nointr 0 0
```

Key options:
- `hard`: Don't silently drop writes on network errors
- `nointr`: Prevent interruption of writes
- `vers=3.0`: Use SMB 3.0 for better error handling

---

## 📋 Action Items

### Immediate (Sprint 1)
- [x] Identify corrupted file ("Glory Road")
- [ ] Delete and re-download "Glory Road"
- [ ] Free up storage to < 90% on `/external/media`
- [ ] Free up storage to < 95% on NAS

### Short-term (Sprint 2)
- [ ] Deploy automated media validation script
- [ ] Configure qBittorrent pre-allocation
- [ ] Set up storage monitoring alerts (Prometheus/Grafana)
- [ ] Update CIFS mount options for stricter error handling

### Long-term (Sprint 3-4)
- [ ] Implement automated cleanup policies
- [ ] Consider storage expansion (additional external drive or NAS upgrade)
- [ ] Migrate to a more robust storage solution (e.g., direct-attached storage vs. CIFS)

---

## 📈 Success Metrics

- **Zero corrupted files** detected in post-download validation
- **Storage usage** maintained below 90% at all times
- **No playback freezing** reported on any device
- **Automated detection** catches issues before user playback

---

## 🔗 Related Documents

- [IMMEDIATE_ACTION_PLAN.md](IMMEDIATE_ACTION_PLAN.md) - Fix #4: Storage capacity
- [SERVER_AUDIT_ANALYSIS.md](SERVER_AUDIT_ANALYSIS.md) - Initial storage findings
- [PLEX_PLAYBACK_FREEZING_INVESTIGATION.md](PLEX_PLAYBACK_FREEZING_INVESTIGATION.md) - Network-related freezing (different issue)
- [scripts/scan_media_integrity.sh](scripts/scan_media_integrity.sh) - Automated corruption scanner

---

**Conclusion**: The "random file playback issues" are **not random** - they correlate directly with files downloaded during critical storage periods (98-100% full). The solution is two-fold: (1) immediate remediation via re-download, and (2) prevention via storage management and automated validation.

