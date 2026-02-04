# Comprehensive Duplicate Media Analysis

**Date**: 2026-01-02
**Scope**: **Full library scan - ALL duplicate types**
**Critical Finding**: **~110GB wasted on duplicates** (not the initial 40GB estimate)

---

## 🚨 **CORRECTED Summary** (User Was Right!)

Initial analysis **only checked cross-location duplicates** (NAS↔USB) and found 3 TV shows.

**Comprehensive scan revealed**:
- ✅ **NAS↔USB**: 3 TV show duplicates (~40GB)
- 🚨 **NAS Internal TV**: 232 duplicate files (~107GB)
- ⚠️ **NAS Internal Movies**: 5 duplicate titles (~17GB)

**Total Duplicate Waste**: **~164GB**
**Potential Savings**: **~110GB** (after keeping best quality versions)

---

## 📊 **Library Overview**

| Location | Movies | TV Shows | Kids Movies | Kids TV | Total |
|----------|--------|----------|-------------|---------|-------|
| **NAS** | 799 | 262 | 188 | 0 | 1,249 |
| **USB** | 134 | 104 | 0 | 0 | 238 |

**Storage Status**:
- **NAS**: 5.4TB / 5.4TB (**100% full** - only 13GB free) 🚨
- **USB**: 2.1TB / 2.2TB (**97% full** - only 80GB free) ⚠️

---

## 🔍 **Detailed Duplicate Findings**

### 1️⃣ **Cross-Location Duplicates** (NAS ↔ USB)

#### **Movies**: ✅ No Duplicates
- 0 movies exist in both locations
- Libraries are completely different

#### **TV Shows**: ⚠️ 3 Duplicates
1. **Archer (2009)** - USB: 30 eps (✅ clean) | NAS: 20 eps → **Keep USB**
2. **Bob's Burgers** - USB: 82 eps (✅ clean) | NAS: 57 eps → **Keep USB**
3. **Stranger Things** - USB: 20 eps (✅ clean) | NAS: 1 ep → **Keep USB**

**Action**: Delete 3 NAS folders → **Save ~40GB**

---

### 2️⃣ **NAS Internal TV Duplicates** 🚨 **CRITICAL**

**Statistics**:
- **Total TV episodes**: 1,944
- **Duplicate files**: 232
- **Unique episodes duplicated**: 91
- **Wasted space**: ~107GB
- **Potential savings**: ~53GB

**Root Causes**:
1. Multiple folder names for same show (e.g., `Show (2023)` vs `Show - Season 1 (2023)`)
2. Sonarr import failures leaving orphaned files
3. Season-level folders mixed with show-level folders
4. Failed downloads not cleaned up

#### **Top Offenders**:

| Show | Duplicate Episodes | Folders | Issue |
|------|-------------------|---------|-------|
| **Rick and Morty** | 35+ | 2 | Multiple naming variations |
| **South Park S23** | 10 | 1 | Multiple copies in season folder |
| **Family Guy** | 12 | 1 | Scattered across misorganized folders |
| **Ahsoka** | 8 (full season) | 2 | `Ahsoka (2023)` + `Ahsoka - Season 1 (2023)` |
| **Fallout** | Mixed (11 vs 8) | 2 | Partial overlap - needs review |
| **Bob's Burgers** | Mixed (57 vs 105) | 2 | Different episode sets |
| **Sausage Party** | 14 | 2 | Multiple episode duplicates |
| **Shogun** | 6 | 2 | Season duplicates |

#### **Safe to Delete** (Identical Content):

```bash
# Ahsoka - identical 8 episodes in both folders
rm -rf "/home/youruser/synology/Media/TV Shows/Ahsoka - Season 1 (2023)"
# Savings: ~2.6GB
```

#### **Needs Manual Review**:
- **Rick and Morty**: 35+ duplicates across 2 folders - check Sonarr
- **Bob's Burgers**: 57 vs 105 episodes - different content, not pure duplicates
- **Fallout**: 11 vs 8 episodes - partial overlap
- **Family Guy**: Episodes scattered - reorganization needed
- **South Park Season 23**: 10 duplicates within same folder structure

**Recommended Action**: Use Sonarr's "Manage Series" → "Re-scan" to identify and remove duplicates automatically.

---

### 3️⃣ **NAS Internal Movie Duplicates** ⚠️ **5 Titles**

| Movie | Version 1 | Version 2 | Recommendation | Savings |
|-------|-----------|-----------|----------------|---------|
| **Avengers: Infinity War** | 1080p (5.4GB) | **4K** (2.4GB) | ✅ Keep 4K, delete 1080p | 5.4GB |
| **Black Panther: Wakanda Forever** | Regular (3.0GB) | **1080p BluRay** | ✅ Keep BluRay, delete regular | 3.0GB |
| **Inception** | Regular (1.9GB) | 1080p | 🔍 Compare quality | ~2GB |
| **The Terminator** | Regular (2.1GB) | **1080p** | ✅ Keep 1080p, delete regular | 2.1GB |
| **The To Do List** | Regular (4.6GB) | **1080p** | ✅ Keep 1080p, delete regular | 4.6GB |

**Total Savings**: ~17GB

#### **Safe Cleanup Commands**:

```bash
cd /home/youruser/synology/Media/Movies

# Keep 4K, delete 1080p (note: 4K file is smaller - likely re-encoded)
rm -rf "Avengers Infinity War (2018)[1080p]"

# Keep BluRay, delete regular
rm -rf "Black Panther Wakanda Forever (2022)"

# Need to verify which version is better quality for these:
# - Inception (2010) vs Inception (2010) [1080p]
# - The Terminator (1984) vs The Terminator (1984) [1080p]
# - The To Do List (2013) vs The To Do List (2013) [1080p]
```

---

## 💾 **Total Storage Reclamation**

| Category | Current Waste | Recoverable | Notes |
|----------|--------------|-------------|-------|
| **Cross-location TV** | 40GB | 40GB | Delete NAS versions (USB is source of truth) |
| **NAS Internal TV** | 107GB | ~53GB | Keep best quality, delete duplicates |
| **NAS Internal Movies** | 17GB | 17GB | Keep higher quality versions |
| **TOTAL** | **164GB** | **~110GB** | |

**Impact on NAS**:
- Current free space: 13GB (0.2%)
- After cleanup: **123GB free** (~2.3%)
- **Still critically low** - need to delete more content beyond duplicates

---

## ✅ **Recommended Action Plan**

### **Phase 1: Safe Deletions** (Immediate - ~60GB)

1. **Cross-location TV duplicates** (40GB):
   ```bash
   cd /home/youruser/synology/Media/TV\ Shows
   rm -rf "Archer (2009)"
   rm -rf "Bob's Burgers"
   rm -rf "Stranger Things (2016)"
   ```

2. **Ahsoka duplicate folder** (~2.6GB):
   ```bash
   rm -rf "Ahsoka - Season 1 (2023)"
   ```

3. **Movie duplicates - confirmed lower quality** (~15GB):
   ```bash
   cd /home/youruser/synology/Media/Movies
   rm -rf "Avengers Infinity War (2018)[1080p]"
   rm -rf "Black Panther Wakanda Forever (2022)"
   ```

**Total Phase 1 Savings**: ~57.6GB

---

### **Phase 2: Manual Review Required** (24-48 hours - ~50GB potential)

1. **Rick and Morty Cleanup**:
   - Use Sonarr → Series → "Rick and Morty" → "Manage Episodes"
   - Identify 35+ duplicate episodes
   - Delete lower quality versions
   - **Estimated savings**: 15-20GB

2. **Family Guy Reorganization**:
   - Check Sonarr for proper folder structure
   - Consolidate scattered episodes
   - **Estimated savings**: 5-10GB

3. **South Park Season 23**:
   - Review 10 duplicate episodes
   - Keep highest quality
   - **Estimated savings**: 3-5GB

4. **Remaining Movie Duplicates**:
   - Compare quality for Inception, Terminator, To Do List
   - Delete lower quality versions
   - **Estimated savings**: ~9GB

5. **Bob's Burgers & Fallout**:
   - **Don't delete yet** - different episode counts
   - Compare episode lists to identify true duplicates
   - **Potential savings**: 10-20GB if significant overlap

---

### **Phase 3: Automated Prevention** (Week 2)

1. **Configure Sonarr**:
   - Enable "Delete empty folders" in Media Management
   - Set "Unmonitor deleted episodes"
   - Configure proper naming scheme

2. **Monthly Duplicate Scan**:
   - Schedule `scripts/find_duplicate_media.sh`
   - Set up alerts for new duplicates

3. **Storage Monitoring**:
   - Alert at 85% full
   - Critical at 90% full
   - **Never let storage exceed 95%** to prevent corruption

---

## 🔧 **Tools Created**

- **scripts/find_duplicate_media.sh** - Comprehensive duplicate detector (all types)
- **/tmp/nas_tv_duplicates_full.txt** - Complete list of 232 duplicate TV files
- **/tmp/nas_movie_dups.txt** - List of 5 duplicate movies

---

## 📚 **Related Documentation**

- [MEDIA_SCAN_RESULTS.md](MEDIA_SCAN_RESULTS.md) - Corruption scan (14 corrupted files)
- [MEDIA_CORRUPTION_ANALYSIS.md](MEDIA_CORRUPTION_ANALYSIS.md) - Why low storage causes corruption
- [IMMEDIATE_ACTION_PLAN.md](IMMEDIATE_ACTION_PLAN.md) - Original server audit action items
- [scripts/find_duplicate_media.sh](scripts/find_duplicate_media.sh) - Duplicate detection tool

---

## 🎯 **Key Takeaways**

1. ✅ **User was correct** - initial scan missed 232 internal TV duplicates
2. 🚨 **~110GB recoverable** from duplicates (not initial 40GB estimate)
3. ⚠️ **Even after cleanup**, NAS will only have ~123GB free (~2%)
4. 🚨 **Critical**: Must address root storage shortage beyond duplicates
5. 📋 **Root cause**: Sonarr import issues + inconsistent folder naming

**Bottom Line**: Duplicates are a symptom, not the root problem. **Storage capacity expansion is mandatory** to prevent ongoing corruption and duplicate accumulation.

---

**Last Updated**: 2026-01-02
**Next Action**: Execute Phase 1 safe deletions (~60GB)

