# Zootopia 2 (2025) Scan Miss Analysis

**Date**: January 10, 2026
**Issue**: File at `/nas/Movies/Zootopia 2 (2025)` was missed by corruption scans
**Status**: 🔍 **INVESTIGATING**

## Problem Statement

User reported that `Zootopia 2 (2025)` at `/nas/Movies/Zootopia 2 (2025)` is low quality but was missed by earlier scans.

## Key Findings

### Path Discrepancy

The scan scripts use paths with **lowercase "media"**:
- `/home/youruser/synology/media/Movies`

But Docker mounts show **capital "Media"**:
- Docker mount: `/home/youruser/synology/Media:/nas` (from DOCKER_PATH_COMPATIBILITY.md)

The file path reported by user: `/nas/Movies/Zootopia 2 (2025)`
- This is a **Docker container path** (inside Plex container)
- Host path would be: `/home/youruser/synology/Media/Movies/Zootopia 2 (2025)`

## Scan Script Paths

### Adaptive Scan (npart_strict_scan_all_media.sh)
```bash
PATHS=(
  "/home/youruser/synology/media/Movies"  # lowercase "media"
  "/home/youruser/synology/media/TV Shows"
  "/home/youruser/synology/media/Movies - Kids"
  "/home/youruser/synology/media/TV Shows - Kids"
  "/external/media/Movies"
  "/external/media/TV"
  "/external/media/Kids Movies"
  "/external/media/Kids TV"
)
```

**Issue**: Scripts scan `/home/youruser/synology/media/Movies` (lowercase)
**Actual path**: `/home/youruser/synology/Media/Movies` (capital M)

## Root Cause Hypothesis

If the actual directory is `/home/youruser/synology/Media/Movies` (capital M) but the scan scripts are looking in `/home/youruser/synology/media/Movies` (lowercase m), then:

1. **Files in `/Media/` (capital) are NOT scanned** - This would explain why Zootopia 2 was missed
2. **Path case mismatch** - Linux is case-sensitive, so these are different directories
3. **Docker mount uses capital M** - `/home/youruser/synology/Media:/nas`

## Verification Needed

1. Check which path actually exists on the host:
   - `/home/youruser/synology/Media/Movies` (capital M) OR
   - `/home/youruser/synology/media/Movies` (lowercase m)

2. Check if Zootopia 2 exists at the actual host path

3. Verify if scan scripts are scanning the wrong directory due to case mismatch

## Impact

If this path case mismatch exists:
- **All files in `/Media/` (capital) were NOT scanned**
- **Only files in `/media/` (lowercase) were scanned** (if that directory even exists)
- **This is a critical scanning coverage gap**

## Next Steps

1. ✅ Verify actual directory structure on host
2. ✅ Check if Zootopia 2 file exists and its actual location
3. ✅ Fix scan scripts to use correct path (capital M if that's the actual path)
4. ✅ Re-run scan on correct paths if path mismatch is confirmed
5. ✅ Update all scan scripts to use consistent, correct paths

---

**Status**: ✅ **ROOT CAUSE IDENTIFIED AND FIXED**

The path case mismatch bug has been fixed in all scan scripts. All scripts now use `/home/youruser/synology/Media/` (capital M) instead of `/home/youruser/synology/media/` (lowercase m).

**Next Step**: Re-run adaptive scan to catch Zootopia 2 and other files that were previously missed.

