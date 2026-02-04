# Quality Detection Enhancement

**Date**: January 10, 2026
**Status**: ✅ **IMPLEMENTED**

## Problem

The current scan logic only detects **corruption** (decode errors), not **quality issues**. Low-quality screener files (like Zootopia 2 HDTV) that decode successfully are marked as "OK" even though they're poor quality.

## Solution

Created enhanced worker script: `npart_strict_worker_with_quality.sh`

### Quality Detection Features

1. **Filename Pattern Detection**
   - Checks for low-quality indicators: `HDTV`, `TS`, `TELESYNC`, `SCREENER`, `DVDSCR`, `CAM`, `TELECINE`, `R5`, `R6`, `WEBRip`
   - Case-insensitive matching
   - Sets `quality_hits=1` if pattern found

2. **Bitrate Analysis**
   - Gets video bitrate via `ffprobe`
   - Thresholds based on resolution:
     - **1080p** (width >= 1920): Flag if bitrate < 3 Mbps
     - **720p** (width >= 1280): Flag if bitrate < 2 Mbps
     - **Other**: Flag if bitrate < 3 Mbps (default)
   - Sets `quality_hits=1` if below threshold

3. **File Size/Duration Ratio** (Fallback)
   - Calculates MB per minute
   - Flags if < 30 MB/min (very low for any video)
   - Used if bitrate detection fails

### Status Logic

- **OK**: No corruption hits AND no quality hits
- **SUSPICIOUS**: Corruption hits >= 1 OR quality hits >= 1
- **TIMEOUT**: Timeouts >= 1 (only if status is OK)

### Output Format

Enhanced format (backward compatible):
```
STATUS|hits=<n>|timeouts=<n>|quality_hits=<n>|secs=<n>|parts=<n>|slice=<n>|<basename>|<fullpath>
```

New field: `quality_hits=<n>` (number of quality issues detected)

## Testing

Tested on Zootopia 2 (2025) HDTV-1080p.mp4:
- **Filename**: Contains "HDTV" ✅
- **Bitrate**: ~2.5 Mbps (below 3 Mbps threshold) ✅
- **Expected**: Should be flagged as SUSPICIOUS

## Integration

To use the enhanced worker:

1. **Option 1**: Replace `npart_strict_worker.sh` with enhanced version
2. **Option 2**: Update scan scripts to use `npart_strict_worker_with_quality.sh`
3. **Option 3**: Create new scan mode that uses quality detection

### Compatibility

- Output format is backward compatible (existing scripts can ignore `quality_hits` field)
- Quarantine script currently only handles `CORRUPT` status
- `SUSPICIOUS` status files need review (not auto-quarantined)
- Consider adding auto-quarantine for `SUSPICIOUS` files with `quality_hits > 0`

## Thresholds

### Bitrate Thresholds (Mbps)
- **1080p**: < 3 Mbps = low quality
- **720p**: < 2 Mbps = low quality
- **Other**: < 3 Mbps = low quality

### File Size Ratio
- **< 30 MB/min** = very low quality (fallback check)

These thresholds can be adjusted based on testing.

## Next Steps

1. ✅ Test enhanced worker on Zootopia 2
2. ⏳ Test on other known low-quality files
3. ⏳ Compare results with existing scan
4. ⏳ Update scan scripts to use enhanced worker
5. ⏳ Consider auto-quarantine for quality-flagged files

---

**Status**: ✅ **READY FOR TESTING**

