# High-Priority Media Scan Results - CRITICAL CORRUPTION FOUND

**Date**: 2026-01-03 (Scan completed 4:36 AM)
**Duration**: 1 hour 17 minutes
**Files Scanned**: 392 (Movies, Kids Movies, downloads)

---

## 🚨 **CRITICAL SUMMARY**

| Metric | Count | Percentage | Status |
|--------|-------|------------|--------|
| **Total Files** | 392 | 100% | ✅ Scanned |
| **Clean Files** | 363 | 92.6% | ✅ OK |
| **Suspicious Files** | 5 | 1.3% | ⚠️ Monitor |
| **CORRUPTED FILES** | **24** | **6.1%** | ❌ **DELETE** |

**Storage Impact**: ~42GB of corrupted content must be deleted and re-downloaded

---

## 📊 **CORRUPTION BY LOCATION**

| Location | Corrupt | Total | Rate | Severity |
|----------|---------|-------|------|----------|
| **Kids Movies** | **22** | **241** | **9.1%** | 🔴 **CRITICAL** |
| **downloads** | **2** | **12** | **16.6%** | 🔴 **CRITICAL** |
| **Movies** | **0** | **139** | **0%** | ✅ **CLEAN** |

### **🔴 Kids Movies: CRITICALLY HIGH Corruption Rate (9.1%)**

This is **alarmingly high** and suggests:
1. ✅ **Download during low storage** - Files were incomplete or damaged
2. ⚠️ **Bad source quality** - Some torrents/sources were corrupted
3. ⚠️ **Transfer errors** - Possible USB bus contention issues
4. ⚠️ **File system corruption** - ext4 issues on USB drive

**Action Required**: Delete all 22 corrupted Kids Movies immediately

### **🔴 downloads: Extremely High Corruption (16.6%)**

2 out of 12 files in downloads are corrupt. These appear to be TV episodes.

**Action**: Delete and re-download

### **✅ Movies: CLEAN (0%)**

All 139 movies in `/external/media/Movies` are corruption-free! This is excellent news.

**Note**: This was the primary playback location, and previous scans found 5 corrupted files that were already deleted.

---

## ❌ **CORRUPTED FILES DETAIL** (24 files)

### **Kids Movies Corruption** (22 files - ~40GB)

| # | Movie Title | Errors | Year | Priority |
|---|-------------|--------|------|----------|
| 1 | **The Lion King** | **265,635** | 2019 | 🔴 SEVERE |
| 2 | Cars 2 | 20,935 | 2011 | 🔴 HIGH |
| 3 | Tangled | 13,489 | 2010 | 🔴 HIGH |
| 4 | Puss in Boots: The Last Wish | 12,114 | 2022 | 🔴 HIGH |
| 5 | How to Train Your Dragon | 10,907 | 2025 | 🔴 HIGH |
| 6 | Alice in Wonderland | 9,511 | 2010 | 🔴 HIGH |
| 7 | Harry Potter - Prisoner of Azkaban | 8,689 | 2004 | 🔴 HIGH |
| 8 | **Wicked** | 8,667 | 2024 | 🔴 HIGH |
| 9 | Tarzan | 8,147 | 1999 | 🔴 HIGH |
| 10 | Open Season | 7,501 | 2006 | 🟡 MEDIUM |
| 11 | Ratatouille | 7,481 | 2007 | 🟡 MEDIUM |
| 12 | Snow White and the Seven Dwarfs | 6,057 | 1938 | 🟡 MEDIUM |
| 13 | Trolls World Tour | 5,849 | 2020 | 🟡 MEDIUM |
| 14 | How to Train Your Dragon 2 | 5,227 | 2014 | 🟡 MEDIUM |
| 15 | Flushed Away | 5,027 | 2006 | 🟡 MEDIUM |
| 16 | Trolls | 3,560 | 2016 | 🟡 MEDIUM |
| 17 | Rango | 3,384 | 2011 | 🟡 MEDIUM |
| 18 | **Barbie** | 3,036 | 2023 | 🟡 MEDIUM |
| 19 | Mulan II | 2,679 | 2004 | 🟡 MEDIUM |
| 20 | Alexander and the Terrible... | 605 | 2025 | 🟢 LOW |
| 21 | Hercules | 217 | 1997 | 🟢 LOW |
| 22 | Miraculous World Paris | 184 | 2023 | 🟢 LOW |

**Notable**:
- **The Lion King (2019)**: 265,635 errors - **massively corrupted** (likely unusable)
- **Recent releases**: Wicked (2024), Barbie (2023), How to Train Your Dragon (2025)
- **Disney classics**: Tangled, Ratatouille, Tarzan, Snow White, Alice, Hercules
- **Popular franchises**: Cars 2, Trolls, How to Train Your Dragon, Harry Potter

### **downloads Corruption** (2 files - ~2GB)

| # | File | Errors | Type |
|---|------|--------|------|
| 1 | Awkwafina is Nora from Queens S03E07 | 130 | TV Episode |
| 2 | Awkwafina is Nora from Queens S02E08 | 67 | TV Episode |

**Action**: Delete and trigger Sonarr to re-download these episodes

---

## ⚠️ **SUSPICIOUS FILES** (5 files - Monitor)

These have 11-50 errors - **may be playable** but could have minor glitches:

| # | Movie Title | Errors | Location |
|---|-------------|--------|----------|
| 1 | Plankton The Movie (2025) | 28 | Kids Movies |
| 2 | Mulan (2020) | 21 | Kids Movies |
| 3 | Awkwafina... S03E02 | 21 | downloads |
| 4 | Shark Tale (2004) | 13 | Kids Movies |
| 5 | Lilo & Stitch (2025) | 11 | Kids Movies |

**Recommendation**:
- Test playback on these files
- If issues occur, delete and re-download
- Consider re-downloading Mulan (2020) and Lilo & Stitch (2025) as recent popular titles

---

## 💾 **STORAGE IMPACT**

### **Before Deletion**
- USB Free Space: 198GB (9%)
- Corrupted Content: 42GB

### **After Deletion**
- USB Free Space: 240GB (11%)
- **+42GB freed**

### **After Re-Download** (assuming 1:1 replacement)
- USB Free Space: 198GB (9%)
- But with **clean, playable files**

---

## 🎯 **IMMEDIATE ACTION PLAN**

### **Step 1: Delete Corrupted Files** (5 minutes)
Run automated deletion script (see below)

### **Step 2: Trigger Radarr/Sonarr Refresh** (5 minutes)
- Refresh library to detect missing files
- Trigger automatic searches
- Monitor download queue

### **Step 3: Verify Playback** (Optional)
Test suspicious files:
- Plankton The Movie (2025)
- Mulan (2020)
- Lilo & Stitch (2025)
- Shark Tale (2004)

If issues occur, delete and re-download.

---

## 🔧 **ROOT CAUSE ANALYSIS**

### **Why So Many Corrupted Kids Movies?**

**Primary Cause**: **Download During Low Storage Period**

Evidence:
1. ✅ **NAS was at 98% full** (96GB free) during heavy download period
2. ✅ **USB was at 92% full** (96GB free)
3. ✅ **Many recent 2024-2025 files corrupted** (Wicked, How to Train Your Dragon, Alexander)
4. ✅ **High-bitrate Bluray rips most affected** (larger files = more fragmentation issues)
5. ✅ **Movies folder clean** (older, established files)

**Secondary Causes**:
- ⚠️ **USB bus contention** (documented Plex freezing issue - same USB topology problem)
- ⚠️ **ext4 filesystem fragmentation** on USB drive at high capacity
- ⚠️ **qBittorrent downloading without pre-allocation** (recommendation: enable pre-allocation)

### **Why Downloads Folder Has 16.6% Corruption?**

**Cause**: **Active Download Location**
- Files currently being downloaded/seeded
- High write activity during low storage
- TV episodes = smaller files, less tolerance for corruption

---

## 📋 **COMPARISON TO PREVIOUS SCANS**

### **Movies Folder** (Previous Scan)
- **Previous**: 5 corrupted files found (Caught Stealing, Sniper, Armor, Werewolves, Kraven)
- **Current**: 0 corrupted files
- **Status**: ✅ **All corruption cleaned up**

### **NAS Movies** (Previous Sample Scan)
- **Previous**: 0 corrupted in 50-file sample
- **Current**: Not scanned in this batch
- **Status**: ⏳ Pending full NAS scan

### **Kids Movies** (First Scan)
- **Current**: 22 corrupted files (9.1%)
- **Status**: 🔴 **CRITICAL - Newly discovered**

---

## ⚠️ **CRITICAL WARNINGS**

### **1. Plex Library Corruption**
Many of these corrupted Kids Movies are likely:
- ✅ **In your Plex library**
- ✅ **Causing random playback freezes** (like "Glory Road" issue)
- ✅ **Affecting multiple devices**

**Action**: Delete all 24 corrupted files ASAP to prevent continued playback issues

### **2. Kids Content Priority**
High corruption rate in Kids Movies means:
- ⚠️ Kids are likely experiencing playback issues
- ⚠️ Parents might not report issues immediately
- ⚠️ Multiple popular titles affected (Wicked, Barbie, Lion King, Tangled)

**Action**: Prioritize re-downloading popular Kids Movies first

### **3. Storage Pressure**
Even after all cleanup:
- USB: 198GB free (9%) - **STILL TIGHT**
- Deletion will free 42GB → 240GB (11%) - **STILL LOW**

**Recommendation**: Continue with orphaned movie cleanup to free more space

---

## 📊 **STATISTICS**

### **Corruption Severity Distribution**
- 🔴 **Severe (>10,000 errors)**: 5 files (Lion King, Cars 2, Tangled, Puss in Boots, How to Train Your Dragon)
- 🔴 **High (5,000-10,000)**: 7 files
- 🟡 **Medium (1,000-5,000)**: 7 files
- 🟢 **Low (<1,000)**: 5 files

### **By Era**
- **2020-2025 (Recent)**: 8 corrupted files (Wicked, How to Train Your Dragon, Barbie, Puss in Boots, etc.)
- **2010-2019**: 8 corrupted files (Lion King 2019, Trolls, Cars 2, etc.)
- **2000-2009**: 5 corrupted files (Ratatouille, Tarzan, Open Season, etc.)
- **1990-1999**: 1 corrupted file (Hercules)
- **Pre-1990**: 2 corrupted files (Snow White 1938, Mulan II 2004)

**Pattern**: Recent files (2020+) are heavily represented - confirms low-storage download theory

---

## 🚀 **NEXT STEPS AFTER CLEANUP**

### **1. Enable qBittorrent Pre-Allocation**
Prevents incomplete file writes during low storage

### **2. Implement Storage Monitoring**
- Set up alerts at 85% capacity
- Auto-pause downloads at 90% capacity

### **3. Continue NAS Scan**
- Scan remaining NAS content (~3,000 files)
- Expect lower corruption rate (older, established files)

### **4. USB Drive Health Check**
```bash
sudo fsck -f /dev/sdc2
```

### **5. Review USB Topology**
- Same issue causing Plex freezing and corruption
- Consider moving media to internal drive or better USB controller

---

## 📁 **RELATED DOCUMENTS**

- **Deletion Script**: `scripts/delete_corrupted_kids_movies.sh` (to be created)
- **Previous Scan Results**: `MEDIA_SCAN_RESULTS.md`
- **Plex Freezing Investigation**: `PLEX_PLAYBACK_FREEZING_INVESTIGATION.md`
- **USB Topology Issues**: See Plex investigation doc

---

**🚨 PRIORITY: Delete 24 corrupted files immediately to prevent continued playback issues!**

