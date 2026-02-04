# Missing Files Investigation - January 10, 2025

## Summary

The adaptive scan completed on January 10, 2025, but only processed **3,244 files out of 3,844 expected files**, leaving **600 files unprocessed**.

## Root Cause

**Critical Bug in Worker Script**: The `npart_strict_worker_with_quality.sh` script had a bug where it would exit silently without writing results when `check_quality()` returned `1` (indicating no quality issues found).

### Technical Details

1. **The Bug**: The script uses `set -euo pipefail`, which causes the script to exit immediately if any command returns a non-zero exit code.

2. **The Problem**: The `check_quality()` function returns:
   - `0` if quality issues are found (quality_hits incremented)
   - `1` if no quality issues are found

3. **The Failure**: When `check_quality()` returned `1` (no quality issues), the script would exit due to `set -e` before reaching the code that writes the result to the results file.

4. **The Impact**: Any file that passed quality checks (no low-quality indicators) would cause the worker script to exit silently without writing a result, making it appear as if the file was never processed.

### Fix Applied

Modified line 147 in `scripts/npart_strict_worker_with_quality.sh`:

```bash
# Before (buggy):
check_quality "$FILE" "$base"

# After (fixed):
check_quality "$FILE" "$base" || true
```

The `|| true` prevents the script from exiting when `check_quality` returns `1`, allowing the script to continue and write the result.

## Missing Files Analysis

### Breakdown by Path

- **290 files** from `/home/youruser/synology/Media/` (NAS)
- **143 files** from `/external/media/Kids TV` (USB)
- **123 files** from `/external/media/TV` (USB)
- **28 files** from `/external/media/Kids Movies` (USB)
- **19 files** from `/external/media/Movies` (USB)

**Total: 603 missing files**

### Files Status

- ✅ **All 603 files still exist** on disk
- ✅ **All files have proper permissions** (readable)
- ✅ **299 files were in the previous scan** (should have been processed in quality-only mode)
- ❌ **None were processed** due to the worker script bug

### Sample Missing Files

- `/external/media/Kids Movies/Aladdin.1992.1080p.BluRay.H264.AAC-RARBG/Aladdin (1992) Bluray-1080p.mkv`
- `/external/media/Kids Movies/Aladdin and the King of Thieves (1996)/Aladdin and the King of Thieves (1996) Bluray-1080p.mkv`
- `/external/media/Kids Movies/Alvin and the Chipmunks Chipwrecked (2011)/Alvin and the Chipmunks Chipwrecked (2011) Bluray-1080p.mkv`
- And 600 more...

## Files List

The complete list of 603 missing files has been saved to:
- **Server**: `/home/youruser/stable_scan/results/missing_files_from_scan_20260110.txt`

## Next Steps

1. ✅ **Fix Applied**: Worker script has been fixed and tested
2. ⏳ **Re-run Scan**: Re-run the adaptive scan to process the 603 missing files
3. ⏳ **Verify**: Confirm all files are processed in the next scan

## Testing

The fix was tested on a missing file:
```bash
# Before fix: Script exited without writing result
# After fix: Script writes result successfully
OK|hits=0|timeouts=0|quality_hits=0|secs=0|parts=20|slice=10|Aladdin (1992) Bluray-1080p.mkv|/external/media/Kids Movies/...
```

## Impact

- **Files Affected**: 603 files (15.7% of expected files)
- **Scan Completion**: 84.4% (3,244 / 3,844)
- **Root Cause**: Worker script bug causing silent failures
- **Fix Status**: ✅ Fixed and tested

## Related Files

- `scripts/npart_strict_worker_with_quality.sh` - Fixed worker script
- `scripts/npart_strict_scan_all_media.sh` - Scan runner (no changes needed)
- `/home/youruser/stable_scan/results/missing_files_from_scan_20260110.txt` - Missing files list

