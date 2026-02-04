# Zootopia 2 Detection Analysis

**Date**: January 10, 2026
**Status**: ✅ **ROOT CAUSE IDENTIFIED**

## Test Results

### Scan Test
- **Result**: `OK|hits=0|timeouts=0`
- **Status**: File was marked as **OK** (not flagged)

### File Properties
- **Filename**: `Zootopia 2 (2025) HDTV-1080p.mp4`
- **Size**: 1.96 GB (2111656486 bytes)
- **Duration**: 102 minutes (6133 seconds)
- **Resolution**: 1920x800
- **Bitrate**: ~2.5 Mbps (format bitrate: 2.75 Mbps)
- **Codec**: h264
- **Quality Indicator**: ✅ **"HDTV" in filename** (screener/low-quality source)

### FFmpeg Test
- **Start decode**: Exit code 0 (success)
- **Middle decode**: Exit code 0 (success)
- **Result**: No decode errors detected

## Root Cause

### The Problem

**Current scan logic ONLY detects CORRUPTION (decode errors), not QUALITY issues.**

1. ✅ File is **valid and decodable** (no corruption)
2. ❌ File is **low quality** (HDTV screener, low bitrate)
3. ❌ Current logic doesn't check for quality indicators

### Why It Wasn't Flagged

The scan worker (`npart_strict_worker.sh`) uses:
- `-loglevel error -xerror` - Only flags on decode errors
- No quality checks (bitrate, filename patterns, etc.)

**Result**: Low-quality screeners that decode successfully are marked as "OK"

## Quality Indicators

### Filename Patterns (Low Quality)
- `HDTV` (✅ Found in Zootopia 2)
- `TS` / `TELESYNC`
- `SCREENER` / `DVDSCR`
- `CAM` / `TELECINE`
- `R5` / `R6`
- `WEBRip` (sometimes low quality)

### Bitrate Thresholds
- **Excellent 1080p**: 8-15 Mbps
- **Good 1080p**: 5-8 Mbps
- **Acceptable 1080p**: 3-5 Mbps
- **Low quality**: < 3 Mbps (⚠️ **Zootopia 2: 2.5 Mbps**)

### File Size vs Duration
- **Zootopia 2**: 1.96 GB for 102 minutes = ~19 MB/min
- **Typical 1080p**: 50-100 MB/min
- **Indicates**: Very compressed/low quality

## Solution: Add Quality Detection

The scan logic needs to be enhanced to detect **both corruption AND quality issues**.

### Proposed Enhancement

Add quality checks to the worker script:

1. **Filename Pattern Detection**
   - Check for low-quality indicators in filename
   - Flag files with: HDTV, TS, SCREENER, CAM, etc.

2. **Bitrate Analysis**
   - Calculate average bitrate
   - Flag files below quality threshold (e.g., < 3 Mbps for 1080p)

3. **File Size Analysis**
   - Compare file size to duration
   - Flag files with suspiciously low size/duration ratio

4. **Combined Status**
   - `CORRUPT` - Decode errors
   - `LOW_QUALITY` - Valid but low quality (new status)
   - `OK` - Valid and acceptable quality

---

**Status**: 🔧 **ENHANCEMENT NEEDED**

