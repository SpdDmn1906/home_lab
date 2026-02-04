# Quality-Only Mode Optimization

**Date**: January 10, 2026
**Status**: ✅ **IMPLEMENTED**

## Problem

The user requested optimization: files already scanned for corruption should skip corruption checks and only run quality checks, which will speed up the scan significantly.

## Solution

Enhanced the scan workflow to support two modes:

1. **Quality-Only Mode**: Skip corruption checks (decode loops), only run quality checks
2. **Full Check Mode**: Run both corruption and quality checks (for new files)

## Implementation

### Enhanced Worker Script

**File**: `scripts/npart_strict_worker_with_quality.sh`

Added 6th parameter: `QUALITY_ONLY` (0 or 1)
- If `QUALITY_ONLY=1`: Skip all corruption decode checks, only run quality checks
- If `QUALITY_ONLY=0`: Run full check (corruption + quality)

**Quality checks** (always run):
- Filename pattern detection (HDTV, TS, SCREENER, etc.)
- Bitrate analysis
- File size/duration ratio

**Corruption checks** (skipped in quality-only mode):
- 20-part decode sampling (expensive)
- Error detection via ffmpeg

### Enhanced Scan Script

**File**: `scripts/npart_strict_scan_all_media.sh`

Added `PREVIOUS_RESULTS` parameter to accept path to previous scan results.

**Logic**:
1. If `PREVIOUS_RESULTS` provided:
   - Compare file list with previous scan
   - Files in previous scan → quality-only mode (fast)
   - New files → full check mode
2. If no previous results:
   - All files get full check (normal behavior)

### Adaptive Scan Integration

**File**: `scripts/adaptive_corruption_scan.sh`

Auto-detects previous scan results and passes to scan runner:
- Looks for most recent completed scan (excluding current one)
- Passes as `PREVIOUS_RESULTS` to enable optimization

## Performance Impact

### Quality-Only Mode (Fast)
- **Time per file**: ~1-2 seconds (just ffprobe calls)
- **Checks**: Filename patterns, bitrate, file size
- **No decode operations**: Massive time savings

### Full Check Mode (Normal)
- **Time per file**: ~90-250 seconds (20 decode slices)
- **Checks**: Corruption + quality

### Example Savings

For 4,000 files already scanned:
- **Before**: 4,000 files × 150s = 600,000s (~167 hours)
- **After**: 4,000 files × 1.5s = 6,000s (~1.7 hours)
- **Savings**: ~165 hours (99% faster!)

## Usage

The optimization is **automatic** when previous scan results exist. The adaptive scan script automatically detects and uses previous results.

**Manual usage**:
```bash
PREVIOUS_RESULTS=/path/to/previous/scan/results.txt \
WORKERS=8 PARTS=20 SLICE=10 TIMEOUT=120 \
RESULTS=/path/to/new/results.txt \
./npart_strict_scan_all_media.sh
```

## Benefits

1. ✅ **Much faster** for already-scanned files
2. ✅ **Quality detection for all files** (not just new ones)
3. ✅ **No redundant corruption checks**
4. ✅ **Automatic** - works transparently with adaptive scan
5. ✅ **Backward compatible** - works without previous results

---

**Status**: ✅ **READY AND ACTIVE**

