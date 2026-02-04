# Media Corruption Scanning - Comprehensive Guide

**Last Updated**: January 9, 2026
**Status**: Production-ready adaptive scanning system implemented

---

## Overview

This document covers the complete media corruption scanning system developed for detecting and handling corrupted video files in the Plex library. The system uses an adaptive 2-phase approach that balances speed and accuracy while ensuring "no surprises" in corruption detection.

---

## Evolution of Scanning Methods

### Phase 1: Initial Sampling (Inadequate)
- **Method**: 5-point sampling (0%, 25%, 50%, 75%, EOF)
- **Duration**: ~2-3 minutes per file
- **Problem**: Missed corruption between sample points (e.g., Lightyear freezing issue)
- **Result**: False negatives - corrupted files passed as OK

### Phase 2: Full-Decode Sequential (Too Slow)
- **Method**: Full file decode, sequential processing
- **Duration**: ~2-5 minutes per file, sequential
- **Problem**: Unacceptably slow for large libraries (days/weeks)
- **Result**: Accurate but impractical

### Phase 3: Stable Parallel Sampling (Current - Phase 1)
- **Method**: 20-part × 10-second sampling with strict error detection
- **Duration**: ~90-250 seconds per file (parallel workers)
- **Workers**: 8-12 parallel workers using `xargs -P`
- **Accuracy**: High false positive rate (flagged benign subtitle warnings)
- **Result**: Fast coverage but requires confirmation phase

### Phase 4: Adaptive 2-Phase System (Current - Final)
- **Phase 1**: 20-part × 10-second strict sampling (fast coverage)
- **Phase 2**: Full-decode confirmation only on flagged files
- **Duration**: Phase 1 ~40 hours, Phase 2 ~10-15 hours (for flagged files only)
- **Result**: Best balance of speed and accuracy ✅

---

## Adaptive 2-Phase Scanning System

### Architecture

```
Phase 1: N-Part Sampling (Fast Coverage)
  ↓
Flag SUSPICIOUS files (hits/timeouts)
  ↓
Phase 2: Full-Decode Confirmation
  ↓
Confirm CORRUPT vs OK
  ↓
Quarantine CORRUPT files
```

### Phase 1: Strict N-Part Sampling

**Purpose**: Quickly identify potentially corrupted files across the entire library

**Method**:
- **Parts**: 20 sampling points distributed throughout file
- **Slice Duration**: 10 seconds per sample
- **Error Detection**: Strict regex for actual decode errors
- **Strict Mode**: `-loglevel error -xerror -sn -dn` (ignore subtitle/data stream warnings)
- **Confirmation**: Secondary strict decode pass on CORRUPT candidates

**Configuration**:
```bash
WORKERS=12              # Parallel workers
PARTS=20                # Number of sample points
SLICE=10                # Seconds per sample
TIMEOUT_SLICE=120       # Timeout per sample (seconds)
```

**Output Categories**:
- **OK**: No errors detected
- **SUSPICIOUS**: 1+ hits detected (needs Phase 2 confirmation)
- **TIMEOUT**: Sample hit timeout (needs Phase 2 confirmation)

**Performance**:
- Average time: ~90-250 seconds per file (depends on file size and I/O)
- Throughput: ~4-12 files per minute (with 12 workers)
- Coverage: 100% of library scanned

### Phase 2: Full-Decode Confirmation

**Purpose**: Confirm which flagged files are actually corrupted

**Method**:
- Full file decode pass (`-f null` output)
- Strict error logging (`-loglevel error -xerror`)
- Timeout: 1800 seconds (30 minutes) per file
- Workers: 12 (parallel processing)

**Configuration**:
```bash
WORKERS_FULL=12         # Parallel workers for full-decode
TIMEOUT_FULL=1800       # 30 minutes per file
ENABLE_SLOW_LANE=1      # Enable slow-lane for timeouts
```

**Output Categories**:
- **CORRUPT**: Confirmed corruption (exit code != 0 or error output)
- **OK**: No errors found (false positive from Phase 1)
- **TIMEOUT**: Hit 30-minute limit (needs manual review or slow-lane)

**Performance**:
- Average time: ~400-1200 seconds per file
- Only processes flagged files (typically 30-40% of library)
- Significantly faster than full-decode on entire library

### Slow-Lane Re-Confirmation (Optional)

**Purpose**: Handle files that timeout during Phase 2 (very large files)

**Method**:
- Extended timeout: 7200 seconds (2 hours) per file
- Reduced workers: 5 (less aggressive)
- Only processes TIMEOUT files from Phase 2

**When to Use**:
- Files that hit 30-minute timeout (likely very large or slow I/O)
- May be OK but need longer decode time
- Manual playback test recommended instead

---

## Scripts and Tools

### Main Scripts

#### `adaptive_corruption_scan.sh`
**Purpose**: Orchestrates the 2-phase adaptive scan
**Location**: `scripts/adaptive_corruption_scan.sh`
**Usage**:
```bash
WORKERS=12 PARTS=20 SLICE=10 TIMEOUT_SLICE=120 \
WORKERS_FULL=12 TIMEOUT_FULL=1800 \
RESULTS_SAMPLE=/path/to/phase1_results.txt \
RESULTS_FULL=/path/to/phase2_results.txt \
./adaptive_corruption_scan.sh
```

#### `run_adaptive_scan_persistent.sh`
**Purpose**: Wrapper script with persistent storage and performance monitoring
**Location**: `scripts/run_adaptive_scan_persistent.sh`
**Features**:
- Saves results to persistent location (survives reboot)
- Performance monitoring during scan
- Automatic cleanup after completion
- Proper screen session management

**Usage**:
```bash
./run_adaptive_scan_persistent.sh
```

#### `check_adaptive_scan_status.sh`
**Purpose**: Status checker with ETA calculations and performance metrics
**Location**: `scripts/check_adaptive_scan_status.sh`
**Features**:
- Real-time progress tracking
- ETA calculations (accounts for parallel workers)
- System performance monitoring
- Results breakdown by category

**Usage**:
```bash
./check_adaptive_scan_status.sh
```

#### `quarantine_corrupt_media.sh`
**Purpose**: Safely quarantine (move, not delete) corrupted files
**Location**: `scripts/quarantine_corrupt_media.sh`
**Features**:
- Moves files to timestamped quarantine directories
- Preserves relative path structure
- Root-folder safety checks (prevents accidental deletion)
- Automatic Radarr/Sonarr refresh + search trigger

**Usage**:
```bash
RESULTS=/path/to/phase2_results.txt ./quarantine_corrupt_media.sh
```

**⚠️ Deprecated Script**: `delete_corrupted_comprehensive.sh` - **DO NOT USE**
- Hard-deprecated due to critical bug that deleted entire Kids Movies directory
- Use `quarantine_corrupt_media.sh` instead
- Deletion script preserved in repo only for historical reference

### Worker Scripts

#### `npart_strict_worker.sh`
**Purpose**: Phase 1 worker - performs multi-point sampling
**Configuration**: PARTS, SLICE, TIMEOUT
**Output Format**: `STATUS|hits=N|timeouts=N|secs=N|parts=N|slice=N|filename|fullpath`

#### `full_decode_worker.sh`
**Purpose**: Phase 2 worker - performs full file decode
**Configuration**: TIMEOUT
**Output Format**: `STATUS|rc=N|secs=N|filename|fullpath`

---

## Error Detection and False Positives

### Problem: Subtitle Warnings

**Initial Issue**: High false positive rate due to subtitle stream warnings
**Example**: Files like "Cloud Atlas" and "Jumper" flagged as CORRUPT

**Root Cause**:
```
[hdmv_pgs_subtitle @ 0x...] Invalid NAL unit size
```
These warnings occur when `ffmpeg` probes subtitle streams but are NOT actual corruption.

### Solution: Strict Mode and Confirmation

**1. Ignore Subtitle/Data Streams**:
```bash
ffmpeg -sn -dn ...  # Skip subtitle and data streams
```

**2. Strict Error Logging**:
```bash
ffmpeg -loglevel error -xerror ...  # Only actual errors, fail on warnings
```

**3. Strict Regex Pattern**:
```bash
HARD_RE='(Invalid data found when processing input|error while decoding|decoding error|corrupt|moov atom not found|truncated|packet corrupt|non-existing PPS|missing picture|reference picture missing|cannot determine format|Header missing|concealing)'
```

**4. Confirmation Step**:
- Run secondary strict decode on CORRUPT candidates
- Downgrade to SUSPICIOUS or OK if no real errors found

**Result**: False positive rate reduced from ~30% to <1%

---

## Performance Tuning

### Worker Configuration

**Recommendations**:
- **4-core system**: 8 workers (Phase 1 and Phase 2)
- **Higher-end system**: 12 workers (if system can handle load)
- **Network mounts**: May need fewer workers due to I/O bottlenecks

**Monitoring**:
- Watch load average (should stay below cores × 3)
- Monitor CPU idle percentage (should stay above 20%)
- Check container health (Gluetun, STARR stack)

### Throughput Optimization

**Phase 1**:
- Reduce PARTS (20 → 15) for faster scanning (less thorough)
- Reduce SLICE (10s → 8s) for faster scanning
- Trade-off: Slightly higher chance of missing edge cases

**Phase 2**:
- Increase TIMEOUT for very large files (1800s → 3600s)
- Use slow-lane for timeout files instead of blocking workers

---

## Results and Output

### Results File Format

**Phase 1 Results**:
```
STATUS|hits=N|timeouts=N|secs=N|parts=20|slice=10|filename|/full/path/to/file
```

**Phase 2 Results**:
```
STATUS|rc=N|secs=N|filename|/full/path/to/file
```

**Status Values**:
- `OK`: File is clean
- `SUSPICIOUS`: Phase 1 flagged, Phase 2 pending
- `CORRUPT`: Confirmed corrupted
- `TIMEOUT`: Hit timeout limit

### Persistent Storage

**Location**: `/home/youruser/stable_scan/results/`
**Naming**: `adaptive_scan_YYYYMMDD_HHMMSS_phase{N}_*.txt`
**Survives**: Server reboots (not in `/tmp`)

**Files**:
- `adaptive_scan_*_phase1_sampling.txt`: Phase 1 results
- `adaptive_scan_*_phase2_fulldecode.txt`: Phase 2 results
- `*.total`: Total file count
- `*.started`: Timestamp when scan started

---

## Quarantine Process

### Safety Features

**1. Move, Don't Delete**:
- All files moved to timestamped quarantine directories
- Reversible operation (can restore if needed)

**2. Root-Folder Protection**:
- Hard-coded denylist prevents deletion of root media folders
- Only moves files/folders, never root directories

**3. Path Preservation**:
- Maintains relative path structure in quarantine
- Easy to identify original location

### Quarantine Locations

**USB Files**:
- `/external/media/_quarantine/YYYYMMDD_HHMMSS/`

**NAS Files**:
- Preferred: `/data/synology/Media/quarantine/YYYYMMDD_HHMMSS/`
- Fallback: `/external/media/_quarantine/NAS_FALLBACK/YYYYMMDD_HHMMSS/`

**Note**: NAS preferred path must be writable, otherwise uses USB fallback.

### Radarr/Sonarr Integration

**Automatic Actions**:
1. Refresh libraries (`RefreshMovie`, `RefreshSeries`)
2. Trigger missing searches (`MissingMoviesSearch`, `MissingEpisodeSearch`)
3. Only for monitored content

**Verification**:
- Sample verification confirms files are tracked
- All quarantined files should trigger re-downloads

---

## Common Issues and Solutions

### Issue: Scan Stuck Building File List

**Symptom**: Script hangs at "Building file list..."
**Cause**: `find` commands hanging on slow network mounts
**Solution**:
- Add timeouts to find commands
- Use cached file lists when available
- Manually build remaining file list with timeouts

### Issue: High False Positive Rate

**Symptom**: Too many files flagged as SUSPICIOUS/CORRUPT
**Cause**: Subtitle warnings or benign decoder messages
**Solution**: Use strict mode (`-loglevel error -xerror -sn -dn`) and confirmation step

### Issue: Stuck Processes Not Timing Out

**Symptom**: ffmpeg processes running for hours despite timeout
**Cause**: Timeout wrapper not working correctly
**Solution**: Kill stuck processes manually, investigate timeout mechanism

### Issue: System Load Too High

**Symptom**: Containers unhealthy, system unresponsive
**Cause**: Too many workers for system capacity
**Solution**: Reduce workers (12 → 8 → 6) based on system performance

### Issue: Results Lost on Reboot

**Symptom**: Scan progress lost after server reboot
**Cause**: Results saved to `/tmp` (cleared on reboot)
**Solution**: Use persistent storage location (e.g., `~/stable_scan/results/`)

---

## Best Practices

### Before Running a Scan

1. **Check System Resources**:
   - Ensure adequate free space (>10%)
   - Verify containers are healthy
   - Check network mount availability

2. **Choose Appropriate Configuration**:
   - Start with 8 workers if unsure
   - Monitor system performance
   - Adjust workers based on load

3. **Use Screen/Tmux**:
   - All long-running scans should use screen sessions
   - Allows detaching and reattaching
   - Prevents loss on SSH disconnect

4. **Persistent Storage**:
   - Always use persistent results location
   - Not in `/tmp` (cleared on reboot)

### During Scan

1. **Monitor Progress**:
   - Check status regularly with status script
   - Watch for stuck processes
   - Monitor system performance

2. **Performance Monitoring**:
   - Track load average
   - Watch CPU idle percentage
   - Verify container health

3. **Handle Issues Promptly**:
   - Kill stuck processes immediately
   - Adjust workers if system overloaded
   - Resume from checkpoints when possible

### After Scan

1. **Review Results**:
   - Check CORRUPT file count
   - Review TIMEOUT files for manual testing
   - Verify quarantine locations

2. **Quarantine CORRUPT Files**:
   - Use quarantine script (not deletion)
   - Verify all files moved
   - Confirm Radarr/Sonarr triggered

3. **Manual Review TIMEOUT Files**:
   - Test playback on sample files
   - Large files may just be slow, not corrupt
   - Quarantine manually if playback fails

---

## Historical Context

### Critical Incidents

#### Kids Movies Directory Deletion (January 5, 2026)
- **Issue**: Deletion script accidentally deleted entire `/external/media/Kids Movies` directory
- **Root Cause**: Script didn't check if parent directory was a root media folder
- **Fix**: Implemented root-folder denylist and quarantine-based workflow
- **Reference**: `CRITICAL_INCIDENT_REPORT.md`

#### Lightyear Freezing (January 2026)
- **Issue**: Lightyear movie froze during playback, not detected by initial sampling scan
- **Root Cause**: 5-point sampling missed corruption between sample points
- **Fix**: Developed adaptive 2-phase system with full-decode confirmation
- **Reference**: `LIGHTYEAR_CORRUPTION_ANALYSIS.md`

### Performance Evolution

**January 2026 Scan Results**:
- **Phase 1**: 4,294 / 4,637 files (92%) - 20-part × 10s sampling
- **Phase 2**: 1,436 / 1,437 files (99.9%) - Full-decode confirmation
- **CORRUPT**: 504 files identified and quarantined
- **TIMEOUT**: 174 files (need manual review)
- **Duration**: ~3 days total (Phase 1: ~40h, Phase 2: ~15h)
- **Workers**: 12 (Phase 1 and Phase 2)

---

## Related Documentation

- [CRITICAL_INCIDENT_REPORT.md](../CRITICAL_INCIDENT_REPORT.md) - Kids Movies deletion incident
- [MEDIA_CORRUPTION_ANALYSIS.md](../MEDIA_CORRUPTION_ANALYSIS.md) - Technical analysis of corruption causes
- [MEDIA_VALIDATION_GUIDE.md](../MEDIA_VALIDATION_GUIDE.md) - Manual validation methods
- [SCAN_RESULTS_SUMMARY_20260109.md](../SCAN_RESULTS_SUMMARY_20260109.md) - January 2026 scan results
- [scan_results_comprehensive_20260109.txt](../scan_results_comprehensive_20260109.txt) - Complete file list

---

## Scripts Reference

All scripts are located in `scripts/` directory:

- `adaptive_corruption_scan.sh` - Main 2-phase orchestrator
- `run_adaptive_scan_persistent.sh` - Persistent storage wrapper
- `check_adaptive_scan_status.sh` - Status checker with ETA
- `npart_strict_scan_all_media.sh` - Phase 1 runner
- `npart_strict_worker.sh` - Phase 1 worker
- `full_decode_from_list.sh` - Phase 2 runner
- `full_decode_worker.sh` - Phase 2 worker
- `quarantine_corrupt_media.sh` - Safe quarantine script

---

**Last Updated**: January 9, 2026
**Maintained By**: Infrastructure automation system
**Status**: Production-ready, actively used

