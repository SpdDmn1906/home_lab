# Duplicate Media Analysis

**Date**: 2026-01-02
**Scope**: Full library scan across NAS and USB storage
**Result**: **Minimal duplication** - only 3 TV shows

---

## 📊 **Library Overview**

| Location | Movies | TV Shows | Kids Movies | Kids TV | Total Dirs |
|----------|--------|----------|-------------|---------|------------|
| **NAS** (Synology) | 799 | 262 | 188 | 0 | 1,249 |
| **USB** (External) | 134 | 104 | 0 | 0 | 238 |

**Storage Status**:
- **NAS**: 5.4TB / 5.4TB (100% full - only 13GB free) 🚨
- **USB**: 2.1TB / 2.2TB (97% full - only 80GB free) ⚠️

---

## 🔍 **Duplicate Detection Results**

### **Movies**: ✅ **ZERO Duplicates**
- **NAS**: 799 movies
- **USB**: 134 movies
- **Overlap**: **0%**

**Finding**: Your movie libraries are **completely different**. The NAS has a much larger collection (799 vs 134), and the USB contains a curated subset of different titles.

**Recommendation**: No action needed - no duplicates to remove.

---

### **TV Shows**: ⚠️ **3 Duplicates Found**

#### 1. **Archer (2009)**
- **USB**: 30 episodes | 9.4GB | ✅ **CLEAN**
- **NAS**: 20 episodes | 9.4GB
- **Corruption**: None detected (sampled 3 episodes)
- **Recommendation**: ✅ **Keep USB (more episodes), delete NAS**
- **Space Savings**: ~9.4GB

#### 2. **Bob's Burgers**
- **USB**: 82 episodes | 8.5GB | ✅ **CLEAN**
- **NAS**: 57 episodes | 30GB
- **Corruption**: None detected (sampled 3 episodes)
- **Recommendation**: ✅ **Keep USB (more episodes), delete NAS**
- **Space Savings**: ~30GB

#### 3. **Stranger Things (2016)**
- **USB**: 20 episodes | 32GB | ✅ **CLEAN**
- **NAS**: 1 episode | 1GB
- **Corruption**: None detected (sampled 3 episodes)
- **Recommendation**: ✅ **Keep USB (complete series), delete NAS**
- **Space Savings**: ~1GB

---

## 💾 **Storage Reclamation Opportunity**

### **Total Potential Savings**: ~40.4GB
By deleting the 3 NAS TV show duplicates, you can free up approximately **40.4GB** on your critically full NAS.

**Breakdown**:
- Archer (NAS): 9.4GB
- Bob's Burgers (NAS): 30GB
- Stranger Things (NAS): 1GB

**Impact**:
- Current NAS free space: 13GB
- After deletion: **53.4GB free** (still only 1% free, but better)

---

## ✅ **Recommended Actions**

### **Immediate** (This Week):

1. **Delete NAS TV Duplicates** (40.4GB savings):
   ```bash
   ssh youruser@192.168.1.11
   cd /home/youruser/synology/Media/TV\ Shows
   rm -rf "Archer (2009)"
   rm -rf "Bob's Burgers"
   rm -rf "Stranger Things (2016)"
   ```

2. **Verify Deletions in Sonarr/Plex**:
   - Trigger library refresh
   - Ensure Plex/Sonarr points to USB versions

### **Short Term** (Next Week):

3. **Address Critical Storage Emergency**:
   - **NAS**: Need to free **~800GB** (target: 15% free = 810GB)
   - **USB**: Need to free **~250GB** (target: 15% free = 330GB)
   - Options:
     - Delete unwatched/old content
     - Move USB content to NAS (after expanding NAS)
     - Add more storage capacity

4. **Prevent Future Duplicates**:
   - Use **one primary location** per content type
   - Configure Sonarr/Radarr to use consistent paths
   - Run monthly duplicate scans

---

## 📋 **Why So Few Duplicates?**

Your content is **well-organized** with minimal overlap because:
1. **Different purposes**: NAS appears to be the primary library, USB is a curated subset
2. **Different content**: The 134 USB movies don't overlap with the 799 NAS movies
3. **TV shows**: Only 3 of 366 total shows are duplicated (0.8% duplication rate)

**This is actually a GOOD thing** - you're not wasting storage on duplicates!

---

## 🚨 **Critical Reminder: Storage Crisis**

While duplicates are minimal, your **storage is critically full**:
- **NAS**: 100% full (5.4TB / 5.4TB)
- **USB**: 97% full (2.1TB / 2.2TB)

**This causes**:
- ❌ File corruption (as we saw with 14 corrupted movies)
- ❌ Failed downloads
- ❌ System instability

**You MUST free up space** beyond just the 40GB from duplicates. See [MEDIA_SCAN_RESULTS.md](MEDIA_SCAN_RESULTS.md) for the storage management plan.

---

## 🔧 **Script Used**

- **`scripts/find_duplicate_media.sh`** - Duplicate detection across NAS/USB
- **Detection Method**: Title/Year matching (not just filename)
- **Corruption Scanning**: Smart sampling (2-minute sample per episode)

---

## 📚 **Related Documentation**

- [MEDIA_SCAN_RESULTS.md](MEDIA_SCAN_RESULTS.md) - Corruption scan results
- [MEDIA_CORRUPTION_ANALYSIS.md](MEDIA_CORRUPTION_ANALYSIS.md) - Why files got corrupted
- [IMMEDIATE_ACTION_PLAN.md](IMMEDIATE_ACTION_PLAN.md) - Fix #4: Storage Capacity
- [scripts/find_duplicate_media.sh](scripts/find_duplicate_media.sh) - Duplicate detection tool

---

**Last Updated**: 2026-01-02
**Next Scan Recommended**: After freeing up storage (monthly thereafter)

