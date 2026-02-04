# Zootopia 2 Detection Summary

**Date**: January 10, 2026
**Status**: ✅ **SOLUTION IMPLEMENTED AND TESTED**

## Problem Identified

Zootopia 2 (2025) HDTV-1080p.mp4 is a low-quality screener file but was marked as "OK" by the scan.

### Root Cause

**Current scan logic only detects CORRUPTION (decode errors), not QUALITY issues.**

- ✅ File is valid and decodable (no corruption)
- ❌ File is low quality (HDTV screener, ~2.5 Mbps bitrate)
- ❌ Current logic doesn't check for quality indicators

### Test Results

**Original Worker** (`npart_strict_worker.sh`):
- Status: `OK`
- Corruption hits: 0
- **Result**: File not flagged ❌

**Enhanced Worker** (`npart_strict_worker_with_quality.sh`):
- Status: `SUSPICIOUS`
- Corruption hits: 0
- Quality hits: 1 ✅
- **Result**: File flagged correctly! ✅

## Solution Implemented

Created enhanced worker script with quality detection:

1. **Filename Pattern Detection**: Flags files with low-quality indicators (HDTV, TS, SCREENER, CAM, etc.)
2. **Bitrate Analysis**: Flags files with bitrate below threshold (e.g., < 3 Mbps for 1080p)
3. **File Size/Duration Ratio**: Fallback check for very low quality files

### Quality Detection Details

**Zootopia 2 Detection:**
- ✅ Filename contains "HDTV" (detected)
- ✅ Bitrate: ~2.5 Mbps (below 3 Mbps threshold)
- ✅ Status changed from `OK` to `SUSPICIOUS`

## File Properties (Zootopia 2)

- **Filename**: `Zootopia 2 (2025) HDTV-1080p.mp4`
- **Size**: 1.96 GB
- **Duration**: 102 minutes
- **Resolution**: 1920x800
- **Bitrate**: ~2.5 Mbps (very low for 1080p)
- **Codec**: h264
- **Quality Indicators**: HDTV in filename, low bitrate

## Next Steps

### Option 1: Replace Current Worker (Recommended)
Replace `npart_strict_worker.sh` with enhanced version to catch low-quality files in all future scans.

### Option 2: Update Scan Scripts
Modify scan scripts to use `npart_strict_worker_with_quality.sh` instead of the standard worker.

### Option 3: Create New Scan Mode
Create a new scan mode that uses quality detection for targeted quality scans.

## Integration Considerations

1. **Output Format**: Enhanced worker adds `quality_hits` field (backward compatible)
2. **Status Handling**: Quality issues marked as `SUSPICIOUS` (not auto-quarantined)
3. **Quarantine Script**: Currently only handles `CORRUPT` status; `SUSPICIOUS` files need review
4. **Performance**: Quality checks add minimal overhead (single ffprobe call per file)

## Recommendations

1. ✅ **Test enhanced worker on known low-quality files** to verify thresholds
2. ⏳ **Integrate into scan workflow** (replace or update scan scripts)
3. ⏳ **Update quarantine script** to optionally handle `SUSPICIOUS` files with quality hits
4. ⏳ **Adjust thresholds** if needed based on testing

---

**Status**: ✅ **READY FOR INTEGRATION**

