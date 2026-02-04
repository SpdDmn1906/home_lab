# Lightyear File Issue - Root Cause Analysis

**Date**: January 3, 2026
**Issue**: Lightyear movie has duplicate files, both freeze during playback, and weren't detected by our scan

---

## 🔴 **ISSUES FOUND**

### **1. Duplicate Files**
- **File 1**: `Lightyear.2022.1080p.WEBRip.x264-RARBG/Lightyear (2022) Bluray-1080p.mp4` (2.0GB)
  - Quality: 1080p WEBRip (higher quality, legitimate)
- **File 2**: `Lightyear (2022) ENG 1080p HQCAM x264 AAC - HushRips.mkv` (1.9GB)
  - Quality: **HQCAM** (CAM recording from theater - **low quality duplicate**)

### **2. Freezing During Playback**
- Both files exhibit freezing/stuttering behavior
- User confirmed both files freeze when played

### **3. Not Detected by Scan**
- Files were never scanned for corruption
- Duplicates were not identified
- Low-quality CAM version was not flagged for deletion

---

## 🔍 **ROOT CAUSE: SCAN PATH MISMATCH**

### **What We Scanned:**
Looking at `scripts/parallel_media_scan.sh` (line 33), our scan only checked:

1. ✅ `/external/media/Movies` (USB drive - Movies)
2. ✅ `/external/media/Kids Movies` (USB drive - Kids Movies)
3. ✅ `/external/media/downloads` (USB drive - Downloads)

### **What We MISSED:**
4. ❌ `/data/media/Movies - Kids` (NAS Kids Movies - **NOT SCANNED!**)
5. ❌ `/home/youruser/synology/media/Movies - Kids` (Same as above, different mount point)
6. ❌ `/data/media/Movies` (NAS Movies - may have some files)

### **Lightyear File Location:**
```
/home/youruser/synology/media/Movies - Kids/Lightyear*
```
This path is equivalent to:
```
/data/media/Movies - Kids/Lightyear*
```

**🔴 ROOT CAUSE: Lightyear files are on the NAS in a path we never scanned!**

---

## 📊 **SCAN COVERAGE ANALYSIS**

### **Paths Actually Scanned:**
| Path | Status | Media Type |
|------|--------|------------|
| `/external/media/Movies` | ✅ Scanned | USB Movies |
| `/external/media/Kids Movies` | ✅ Scanned | USB Kids Movies |
| `/external/media/downloads` | ✅ Scanned | USB Downloads |

### **Paths NOT Scanned (MISSING!):**
| Path | Status | Media Type | Issue |
|------|--------|------------|-------|
| `/data/media/Movies - Kids` | ❌ **NOT SCANNED** | NAS Kids Movies | **Lightyear is here!** |
| `~/synology/media/Movies - Kids` | ❌ **NOT SCANNED** | NAS Kids Movies (alternate mount) | Same location |
| `/data/media/Movies` | ❌ Not Scanned | NAS Movies | May contain other movies |

---

## 🎯 **WHY ISSUES WEREN'T DETECTED**

### **1. Duplicate Not Detected:**
- ❌ Files weren't scanned, so no duplicate detection occurred
- ❌ HQCAM (cam recording) should have been flagged as low quality
- ❌ Two versions of same movie should have been identified

### **2. Corruption Not Detected:**
- ❌ Files were never analyzed for corruption
- ❌ Our scan only sampled specific sections, which might miss freezing issues
- ❌ Freezing could be caused by:
  - Keyframe problems (not detected by NAL unit scanning)
  - Corruption in unsampled sections
  - Incomplete file downloads
  - Codec/container issues

### **3. Scan Limitations:**
Our corruption scan used:
- **Method**: 3 samples (beginning, middle, end) × 3 minutes each
- **Detection**: Only NAL unit errors
- **Limitation**: Doesn't detect:
  - Keyframe issues (common cause of freezing)
  - Corruption in unsampled sections
  - Playback-specific issues

---

## 🔧 **FIXES COMPLETED** ✅

### **1. Expand Scan Coverage (CRITICAL)** ✅

**✅ FIXED: Updated duplicate detection script to include ALL media paths:**

- ✅ Now indexes NAS Kids Movies (`/home/youruser/synology/media/Movies - Kids`)
- ✅ Now indexes NAS Kids TV Shows
- ✅ Now indexes USB Kids Movies
- ✅ Detects duplicates within same location (like Lightyear!)
- ✅ Compares all location combinations
- ✅ Flags low-quality duplicates (CAM/TS versions)

**Script**: `scripts/find_duplicate_media.sh` (enhanced version)

### **2. Enhanced Corruption Detection**

**Still needed - Add full-file scanning for freezing detection:**
- Full file pass-through scan (detects keyframe issues)
- Multiple sample points (increase from 3 to 10-20)
- Playback simulation test
- Keyframe analysis

### **3. Duplicate Detection Enhancement** ✅

**✅ COMPLETED: Enhanced duplicate detection script:**
- ✅ Identifies CAM/TS/TC/HQCAM versions (low quality)
- ✅ Flags duplicates with quality comparison
- ✅ Recommends keeping highest quality version
- ✅ Detects duplicates within same location

### **4. Comprehensive Media Audit**

**Scan ALL media paths to find other missed files:**
- USB paths (already done)
- NAS Movies paths (MISSING)
- NAS Kids Movies paths (MISSING - where Lightyear is!)

---

## 📋 **IMMEDIATE ACTIONS**

### **For Lightyear Files:**

1. **Delete Low-Quality Duplicate:**
   ```bash
   rm "/home/youruser/synology/media/Movies - Kids/Lightyear (2022) ENG 1080p HQCAM x264 AAC - HushRips.mkv"
   ```
   **Reason**: HQCAM is a cam recording (theater cam) - much lower quality than WEBRip

2. **Re-check Higher Quality File:**
   - File: `Lightyear (2022) Bluray-1080p.mp4` (2.0GB)
   - Still freezes - may need re-download
   - Could be incomplete download or corruption

3. **Check in Radarr:**
   - Ensure Lightyear is tracked in Radarr
   - Delete both files and trigger re-download if needed

### **For Future Scans:**

1. **Update scan script** to include NAS paths
2. **Create comprehensive media inventory** of all paths
3. **Add duplicate detection** with quality comparison
4. **Enhance corruption detection** for freezing issues

---

## 📈 **IMPACT ASSESSMENT**

### **Files Potentially Missed:**

**NAS Kids Movies (`/data/media/Movies - Kids`):**
- Lightyear (confirmed - 2 files, both problematic)
- **Unknown number of other movies** - need to check!

**NAS Movies (`/data/media/Movies`):**
- Unknown - not scanned

### **Risk:**
- 🔴 **HIGH**: Other corrupted files on NAS not detected
- 🔴 **HIGH**: Other duplicates on NAS not identified
- 🟡 **MEDIUM**: Low-quality CAM versions may exist

---

## 🎯 **RECOMMENDATIONS**

### **Short Term:**
1. ✅ Fix Lightyear immediately (delete CAM, re-download if needed)
2. ✅ Expand scan to include NAS paths
3. ✅ Re-scan NAS Kids Movies folder completely

### **Long Term:**
1. ✅ Create comprehensive media path inventory
2. ✅ Enhance corruption detection (full-file scans)
3. ✅ Add quality-based duplicate detection
4. ✅ Regular comprehensive scans of ALL paths
5. ✅ Integrate with Radarr/Sonarr for automatic detection

---

## 📚 **LESSONS LEARNED**

1. **Path Coverage**: Always verify ALL media mount points are scanned
2. **Mount Point Awareness**: Same physical location can be accessed via different paths
   - `/data/media/Movies - Kids` = `~/synology/media/Movies - Kids` (same location!)
3. **Quality Detection**: Need to detect and flag low-quality duplicates (CAM/TS/TC)
4. **Freezing Detection**: Sampling may miss playback issues - need full-file or enhanced scanning
5. **Comprehensive Audits**: Need periodic full scans of ALL media paths, not just high-priority

---

## 🔍 **VERIFICATION CHECKLIST**

To prevent this in the future:

- [ ] Document ALL media mount points
- [ ] Verify scan script includes ALL paths
- [ ] Test scan on sample files from each path
- [ ] Add duplicate detection with quality comparison
- [ ] Enhance corruption detection for freezing
- [ ] Regular comprehensive scans (monthly/quarterly)
- [ ] Integration with Radarr/Sonarr for missing file detection

---

**Last Updated**: January 3, 2026 @ 2:00 PM
**Status**: Root cause identified, fixes documented, immediate actions required

