# Media File Validation Guide

**Purpose**: Detect video file corruption (H.264 NAL errors, container issues) in your Plex library, regardless of when files were downloaded or copied.

---

## 🎯 Quick Start

### Option 1: Run on Media Server (Recommended)

Copy and run the server script directly:

```bash
# Copy script to server
scp scripts/scan_media_server.sh youruser@192.168.1.11:/tmp/

# SSH to server
ssh youruser@192.168.1.11

# Run quick scan on all movies
bash /tmp/scan_media_server.sh /external/media/Movies

# Or scan TV shows
bash /tmp/scan_media_server.sh /external/media/TV

# Deep scan a specific suspicious file
bash /tmp/scan_media_server.sh --deep "/external/media/Movies/Glory Road (2006)"
```

### Option 2: Run from Your Laptop (requires ffmpeg)

```bash
# Install ffmpeg if not already installed
brew install ffmpeg  # macOS

# Quick scan (fast)
./scripts/scan_media_integrity.sh /path/to/media

# Deep scan (thorough but slow)
./scripts/scan_media_integrity.sh --deep /path/to/media
```

---

## 📊 Understanding Scan Modes

### Quick Mode (Default) ⚡
- **Speed**: ~10-15 seconds per file
- **Method**: Validates first 5 minutes + last 5 minutes
- **Use when**: Scanning large libraries (100+ files)
- **Detection rate**: Catches ~95% of corruption issues

**Example**:
```bash
bash scan_media_server.sh /external/media/Movies
# OR
./scripts/scan_media_integrity.sh /external/media/Movies
```

### Deep Mode (Thorough) 🔬
- **Speed**: ~2-5 minutes per file
- **Method**: Full frame-by-frame decode of entire file
- **Use when**: Verifying suspicious files or critical content
- **Detection rate**: 100% guaranteed to find all corruption

**Example**:
```bash
bash scan_media_server.sh --deep "/external/media/Movies/Suspect Movie (2024)"
# OR
./scripts/scan_media_integrity.sh --deep "/external/media/Movies/Suspect Movie (2024)"
```

---

## 🔍 What the Scanner Detects

### 1. **Video Stream Corruption** (Critical)
- H.264/H.265 NAL unit errors
- Invalid video packets
- Decoder submission errors
- **Symptoms**: Freezing, stuttering, black screens during playback
- **Solution**: Delete and re-download

### 2. **Container Issues** (Critical)
- Missing duration metadata
- Corrupt MP4/MKV container
- Invalid moov atom
- **Symptoms**: File won't play at all, or stops after a few seconds
- **Solution**: Delete and re-download

### 3. **Codec Compatibility** (Warning)
- HEVC 10-bit (may not play on Roku, older webOS TVs)
- VP9/AV1 codecs (limited device support)
- **Symptoms**: "Codec not supported" errors
- **Solution**: Re-encode or use a better client (NVIDIA Shield, Apple TV)

### 4. **Suspicious Characteristics** (Warning)
- File size too small for duration/resolution
- Unusual bitrate patterns
- **Symptoms**: Poor quality, possible incomplete download
- **Solution**: Compare with expected file size, consider re-downloading

---

## 📋 Interpreting Results

### Clean File ✅
```
[42] The Matrix (1999).mkv ... OK
```
- No corruption detected
- File should play normally

### Corrupted File ❌
```
[15] Glory Road (2006).mp4 ... CORRUPT (1723 errors)
  File: /external/media/Movies/Glory Road (2006)/Glory Road (2006) Bluray-1080p.mp4
```
- **Action required**: Delete and re-download immediately
- File will freeze/stall during playback

### Suspicious File ⚠️
```
[28] Example Movie (2020).mp4 ... SUSPICIOUS (15 errors)
  File: /external/media/Movies/Example Movie (2020)/Example Movie.mp4
```
- **Action**: Run deep scan to confirm
- May play fine or may have intermittent issues

### Codec Warning 📘
```
[33] High Quality Film (2023).mkv ... OK [HEVC 10-bit: may not work on Roku/webOS]
```
- File is not corrupt
- May not play on certain devices
- Consider re-encoding for compatibility

---

## 🛠️ Workflow: Scanning Your Entire Library

### Step 1: Initial Quick Scan

Scan all your media to identify obvious problems:

```bash
# On server
ssh youruser@192.168.1.11
bash /tmp/scan_media_server.sh /external/media/Movies > /tmp/movies_scan.log 2>&1
bash /tmp/scan_media_server.sh /external/media/TV > /tmp/tv_scan.log 2>&1
```

**Expected time**:
- 500 movies: ~2-3 hours
- 1000 TV episodes: ~3-5 hours

### Step 2: Review Results

Check the logs for corrupted files:

```bash
# View corrupted files only
grep -E "CORRUPT|SUSPICIOUS" /tmp/movies_scan.log
```

### Step 3: Deep Scan Suspicious Files

For any suspicious files, run a deep validation:

```bash
bash /tmp/scan_media_server.sh --deep "/external/media/Movies/Suspicious File (2024)"
```

### Step 4: Re-download Corrupted Files

1. In Radarr/Sonarr, **unmonitor** the file
2. **Delete** the corrupted file from disk
3. **Re-monitor** in Radarr/Sonarr to trigger automatic re-download
4. **Validate** the new file after download

---

## 🔄 Automated Validation (Future Setup)

### Post-Download Validation Script

Add to Radarr/Sonarr as a custom script (`/config/scripts/validate_media.sh`):

```bash
#!/bin/bash
# Radarr/Sonarr post-import validation

FILE="$radarr_moviefile_path"  # or $sonarr_episodefile_path

echo "Validating: $FILE"

# Quick validation
errors=$(docker run --rm -v "$(dirname "$FILE"):/mnt" linuxserver/ffmpeg:latest \
    -ss 0 -t 300 -i "/mnt/$(basename "$FILE")" -f null - 2>&1 | \
    grep -ciE "Invalid NAL|Error splitting" || echo "0")

if [[ "$errors" -gt 50 ]]; then
    echo "ERROR: File corrupted ($errors errors). Marking for re-download."
    # Delete the file and trigger re-download
    rm "$FILE"
    exit 1
fi

echo "File validated successfully."
exit 0
```

**Radarr/Sonarr Setup**:
1. Settings → Connect → Add Custom Script
2. On Import: Checked
3. Path: `/config/scripts/validate_media.sh`

---

## 📈 Expected Results by Library Size

| Library Size | Quick Scan Time | Deep Scan Time | Typical Corruption Rate |
|--------------|-----------------|----------------|-------------------------|
| 100 movies | ~30 min | ~8 hours | 1-3 files |
| 500 movies | ~2.5 hours | ~40 hours | 5-15 files |
| 1000 movies | ~5 hours | ~80 hours | 10-30 files |
| 100 TV episodes | ~30 min | ~8 hours | 2-5 files |
| 1000 TV episodes | ~5 hours | ~80 hours | 10-40 files |

**Note**: Corruption rate assumes previous periods of low storage (95%+). If you've always maintained good storage hygiene, expect <0.5% corruption.

---

## 🚨 Common Issues

### Issue: "Docker image not found"
**Solution**:
```bash
docker pull linuxserver/ffmpeg:latest
```

### Issue: "Permission denied"
**Solution**:
```bash
chmod +x /tmp/scan_media_server.sh
```

### Issue: Scan is too slow
**Solution**: Use quick mode (default), not deep mode, for large libraries. Only deep-scan suspicious files.

### Issue: "File not found" on server scan
**Solution**: Ensure you're using the correct path. Paths on the server are:
- Movies: `/external/media/Movies`
- TV: `/external/media/TV` (if applicable)
- Kids: `/nas/Movies - Kids` (if applicable)

---

## 📊 Sample Output

```
🔬 Media Integrity Scanner (Server Mode)
========================================
Path: /external/media/Movies
Mode: quick

[1] The Matrix (1999).mkv ... OK
[2] Glory Road (2006).mp4 ... CORRUPT (1723 errors)
[3] Inception (2010).mkv ... OK
[4] Interstellar (2014).mkv ... OK [HEVC 10-bit: may not work on Roku/webOS]
[5] Example Film (2020).mp4 ... SUSPICIOUS (15 errors)
...
[500] Zootopia (2016).mp4 ... OK

========================================
📊 SCAN RESULTS
========================================
Total files: 500
Clean files: 495
Corrupted: 2
Suspicious: 3

Full log: /tmp/media_scan_20260102_143022.log

Recommendation: Re-download corrupted files
See log file for full list: /tmp/media_scan_20260102_143022.log
```

---

## 🔗 Related Documents

- [docs/media-corruption-scanning.md](docs/media-corruption-scanning.md) - **Complete adaptive scanning system documentation**
- [MEDIA_CORRUPTION_ANALYSIS.md](MEDIA_CORRUPTION_ANALYSIS.md) - Technical deep dive into corruption causes
- [PLAYBACK_ISSUE_RESOLUTION.md](PLAYBACK_ISSUE_RESOLUTION.md) - Glory Road case study
- [SCAN_RESULTS_SUMMARY_20260109.md](SCAN_RESULTS_SUMMARY_20260109.md) - January 2026 comprehensive scan results
- [IMMEDIATE_ACTION_PLAN.md](IMMEDIATE_ACTION_PLAN.md) - Storage management fixes

## ⚡ Current Production System

As of January 2026, the manual validation methods described above have been superseded by an **automated adaptive 2-phase scanning system**:

- **Phase 1**: Fast N-part sampling (20 parts × 10s) with strict error detection
- **Phase 2**: Full-decode confirmation only on flagged files
- **Quarantine**: Automatic safe quarantine (move, not delete) with Radarr/Sonarr integration

**See**: `docs/media-corruption-scanning.md` for complete documentation and usage instructions.

---

## 💡 Key Takeaways

1. **Corruption can happen anytime**: Low storage, network interruptions, manual copies, drive issues
2. **File size is NOT reliable**: Corrupt files can have correct size
3. **Quick scan first**: Fast triage of large libraries
4. **Deep scan suspicious files**: Confirm before re-downloading
5. **Prevention is key**: Maintain <90% storage, enable disk pre-allocation, automate validation

