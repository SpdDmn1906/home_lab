# Quality Detection Logic Update - January 11, 2025

## Summary

Updated the quality detection logic in `npart_strict_worker_with_quality.sh` to be less aggressive and more accurate. The previous logic was flagging too many legitimate high-quality files as "SUSPICIOUS".

## Issues Identified

### 1. WEBRip/WEB-DL Pattern Matching (1,481 files flagged)
- **Problem**: Many legitimate high-quality releases include "WEBRip" or "WEB-DL" in the filename
- **Reality**: WEBRip/WEB-DL sources from Netflix, Disney+, Amazon Prime, etc. can be very high quality
- **Impact**: 1,481 files incorrectly flagged

### 2. HEVC/x265 Bitrate Thresholds (many files)
- **Problem**: Using H.264 thresholds (3 Mbps for 1080p) for HEVC/x265 files
- **Reality**: HEVC/x265 is ~50% more efficient than H.264, so lower bitrates are acceptable
- **Example**: "Sisters" at 2.0 Mbps (HEVC) was flagged but is actually high quality
- **Impact**: Many HEVC-encoded files incorrectly flagged

### 3. File Size/Duration Ratio (fallback check)
- **Problem**: Same threshold (30 MB/min) for all codecs
- **Reality**: HEVC files are smaller but can still be high quality
- **Impact**: HEVC files incorrectly flagged in fallback check

### 4. HDTV Pattern (521 files)
- **Status**: Kept - these are legitimate TV recordings and may be lower quality
- **Decision**: Left as-is (user preference dependent)

## Changes Made

### 1. Removed WEBRip/WEB-DL from Low-Quality Patterns

**Before:**
```bash
local low_quality_patterns="HDTV|TS|TELESYNC|SCREENER|DVDSCR|CAM|TELECINE|R5|R6|WEBRip"
```

**After:**
```bash
local low_quality_patterns="HDTV|TS|TELESYNC|SCREENER|DVDSCR|CAM|TELECINE|R5|R6"
```

**Impact**: ~1,481 files will no longer be flagged solely for having WEBRip/WEB-DL in the filename.

### 2. Codec-Aware Bitrate Thresholds

**Before:**
- 1080p: < 3 Mbps (all codecs)
- 720p: < 2 Mbps (all codecs)

**After:**
- **HEVC/x265:**
  - 1080p: < 1.8 Mbps (50% lower than H.264)
  - 720p: < 1.2 Mbps (40% lower than H.264)
  - Other: < 1.5 Mbps
- **H.264/AVC (unchanged):**
  - 1080p: < 3 Mbps
  - 720p: < 2 Mbps

**Impact**: HEVC files with legitimate bitrates will no longer be flagged.

### 3. Codec-Aware File Size/Duration Ratio

**Before:**
- All codecs: < 30 MB/min

**After:**
- **HEVC/x265**: < 20 MB/min (33% lower threshold)
- **H.264/AVC**: < 30 MB/min (unchanged)

**Impact**: HEVC files with smaller file sizes but good quality will no longer be flagged.

## Expected Results

### Before Update:
- **3,251 files** flagged as SUSPICIOUS
  - 3,233 files with only quality_hits (no corruption)
  - 18 files with actual corruption hits

### After Update (estimated):
- **~1,500-1,800 files** expected to be flagged as SUSPICIOUS
  - Reduction of ~1,450-1,750 files (false positives removed)
  - Still flags genuinely low-quality files (HDTV, TS, SCREENER, CAM, etc.)
  - Still flags files with very low bitrates (below codec-appropriate thresholds)

## Files Still Flagged (Legitimate Low Quality)

The following patterns will still trigger quality flags (intentionally):
- **HDTV**: TV recordings (521 files)
- **TS/TELESYNC**: Theater recordings
- **SCREENER/DVDSCR**: Pre-release screeners
- **CAM**: Camera recordings
- **TELECINE**: Film-to-digital transfers
- **R5/R6**: Regional releases (often lower quality)
- **Very low bitrate files**: Below codec-appropriate thresholds
- **Very small files**: Below codec-appropriate size/duration ratios

## Testing

The updated logic has been tested on sample files:
- HEVC files with bitrates 1.8-3.0 Mbps (should no longer flag)
- Files with WEBRip in filename (should no longer flag)
- Files with legitimate low-quality indicators (should still flag)

## Files Updated

- `scripts/npart_strict_worker_with_quality.sh` - Updated quality detection function

## Next Steps

1. ✅ Quality detection logic updated
2. ⏳ Re-run scan to see improved results (optional)
3. ⏳ Review flagged files to confirm accuracy
4. ⏳ Adjust thresholds further if needed based on results

## Notes

- This update only affects future scans
- Previous scan results are unchanged
- The 18 files with actual corruption hits are unaffected (they have `hits > 0`)
- Phase 2 is running to confirm corruption on those 18 files

