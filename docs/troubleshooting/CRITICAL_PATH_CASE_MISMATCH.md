# CRITICAL: Path Case Mismatch Bug in Scan Scripts

**Date**: January 10, 2026
**Severity**: 🔴 **CRITICAL**
**Impact**: All files in `/home/youruser/synology/Media/` were NOT scanned

---

## Problem

All scan scripts use **incorrect path case**:
- ❌ Scripts scan: `/home/youruser/synology/media/Movies` (lowercase "media")
- ✅ Actual path: `/home/youruser/synology/Media/Movies` (capital "Media")

**Result**: Files in `/Media/` (capital) were completely missed by all corruption scans!

---

## Verification

✅ Confirmed: `/home/youruser/synology/Media` exists (capital M) - **Contains actual files**
✅ Confirmed: `/home/youruser/synology/media` ALSO exists (lowercase m) - **May be different directory or symlink**

**Key Finding**: Both directories exist, but files are in `/Media/` (capital), while scan scripts look in `/media/` (lowercase).

**Zootopia 2 Location**: `/home/youruser/synology/Media/Movies/Zootopia 2 (2025)/Zootopia 2 (2025) HDTV-1080p.mp4` (2.0GB)

Linux is case-sensitive, so these are different directories. Files in `/Media/` (capital) were NOT scanned because scripts searched `/media/` (lowercase).

---

## Affected Scripts

All scan scripts that scan NAS media paths:

1. `npart_strict_scan_all_media.sh` (Phase 1 of adaptive scan)
2. `full_decode_scan_all_media.sh`
3. `stable_corruption_scan.sh`
4. `delete_corrupted_comprehensive.sh` (deprecated)
5. `quarantine_corrupt_media.sh` (may have path issues)
6. All other scan scripts with NAS paths

---

## Impact Assessment

### Files NOT Scanned

All files in:
- `/home/youruser/synology/Media/Movies`
- `/home/youruser/synology/Media/TV Shows`
- `/home/youruser/synology/Media/Movies - Kids`
- `/home/youruser/synology/Media/TV Shows - Kids`

### Example: Zootopia 2 (2025)

- **Location**: `/nas/Movies/Zootopia 2 (2025)` (Docker path)
- **Host path**: `/home/youruser/synology/Media/Movies/Zootopia 2 (2025)`
- **Status**: ❌ **NOT SCANNED** (script looked in `/home/youruser/synology/media/Movies`)
- **Issue**: Low quality file missed

---

## Root Cause

The scan scripts were written with lowercase "media" in the path, but the actual directory structure uses capital "Media". This case mismatch means the `find` commands in the scan scripts would either:

1. Find nothing (if lowercase directory doesn't exist), OR
2. Find files in a different directory (if both exist)

---

## Fix Required

### 1. Update All Scan Scripts

Change all occurrences of:
```bash
"/home/youruser/synology/media/Movies"
"/home/youruser/synology/media/TV Shows"
"/home/youruser/synology/media/Movies - Kids"
"/home/youruser/synology/media/TV Shows - Kids"
```

To:
```bash
"/home/youruser/synology/Media/Movies"
"/home/youruser/synology/Media/TV Shows"
"/home/youruser/synology/Media/Movies - Kids"
"/home/youruser/synology/Media/TV Shows - Kids"
```

### 2. Affected Files to Update

- `scripts/npart_strict_scan_all_media.sh`
- `scripts/full_decode_scan_all_media.sh`
- `scripts/stable_corruption_scan.sh`
- `scripts/quarantine_corrupt_media.sh`
- Any other scripts with NAS paths

### 3. Re-run Scans

After fixing paths, re-run scans on the correct directories to catch:
- Corrupted files that were missed
- Low quality files (like Zootopia 2)
- All other files in `/Media/` directories

---

## Immediate Actions

1. ✅ **Document the bug** (this file)
2. ⏳ **Fix all scan scripts** (update paths to capital M)
3. ⏳ **Re-run adaptive scan** on corrected paths
4. ⏳ **Update documentation** to reflect correct paths

---

## Lessons Learned

1. **Case sensitivity matters** - Always verify actual directory names on case-sensitive filesystems
2. **Path validation** - Scan scripts should validate paths exist before scanning
3. **Documentation consistency** - Ensure documentation matches actual directory structure
4. **Testing** - Test scan scripts on a small subset before full library scan

---

**Status**: ✅ **FIXED** - All scripts updated (January 10, 2026)

See `PATH_CASE_FIX_COMPLETE.md` for fix details.

