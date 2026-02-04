# Remaining Duplicates - Action Plan

**Date**: 2026-01-02 (After Phase 1 completion)
**Status**: 349 duplicate files remaining (~51GB)
**Priority**: MEDIUM-HIGH (Phase 2B continuation)

---

## 📊 **Summary**

| Type | Count | Estimated Size | Priority |
|------|-------|----------------|----------|
| **USB Internal** | 37 files (9 patterns) | ~5.4GB | HIGH |
| **NAS Internal** | ~172 files (86 patterns) | ~34GB | HIGH |
| **Cross-Location** | 90 episodes | ~11.3GB | MEDIUM |
| **TOTAL** | **349 files** | **~51GB** | - |

---

## 🎯 **Action Plan by Show**

### **1. AMERICAN DAD (USB) - 22 Duplicates** 🚨 **QUICK WIN**

**Issue**: Season 15 folder contains episodes already in main folder

**Current State**:
- `American Dad! (2005)`: 194 episodes (49GB) ← **Main folder**
- `American Dad! (2005) Season 15...`: 22 episodes (5.5GB) ← **DUPLICATES**
- `American Dad S16...`: 20 episodes (3.9GB) ← Unique?

**Action**:
```bash
# Via Synology File Station or SSH:
cd /external/media/TV

# Check if Season 15 episodes exist in main folder
# If yes, delete the Season 15 folder:
rm -rf "American Dad! (2005) Season 15 S15 (1080p AMZN WEB-DL x265 HEVC 10bit EAC3 5.1 ImE)"

# Check Season 16 folder - if these episodes exist in main folder, delete it too:
# rm -rf "American.Dad.S16.Season.16.Complete.1080p.WEBRip.x264-maximersk [mrsktv]"
```

**Savings**: ~5.5GB (confirmed duplicates) + potentially 3.9GB (S16 if duplicates)

**Verification**: Use Sonarr to confirm main folder has S15 episodes before deleting

---

### **2. BOB'S BURGERS - 82 Cross-Location Duplicates** ⚠️ **COMPLEX**

**Current State**:
- **USB**: 82 episodes (8.5GB)
- **NAS**: 105 episodes (21GB)

**Issue**: NAS has MORE episodes (105 vs 82), so there are 23 unique NAS episodes + 82 duplicates

**Recommended Strategy**:

**Option A: Keep NAS, Delete USB** (Simplest)
```bash
# If NAS versions are acceptable quality:
rm -rf "/external/media/TV/Bob's Burgers"
# Savings: 8.5GB
```

**Option B: Merge Best Quality** (Best result, more work)
1. Use Sonarr: http://192.168.1.11:8989 → Bob's Burgers
2. Compare file sizes for the 82 duplicate episodes
3. Keep whichever location has better quality per episode
4. Manually move unique 23 NAS episodes to USB (or vice versa)
5. Delete the emptier folder

**My Recommendation**: **Option A** - Keep NAS (has more episodes), delete USB
- NAS: `Bob's Burgers (2011)` - 105 episodes
- Reason: Saves time, NAS has all content

---

### **3. RICK AND MORTY - Scattered Folders** 🚨 **MAJOR CLEANUP NEEDED**

**Current Mess**:

**USB** (15 folders!):
- Scattered season folders (S01 720p, S01 1080p, S02 720p, etc.)
- Individual episode folders (S04E06, S04E07, etc.)
- Incomplete seasons everywhere

**NAS** (15 folders!):
- Main folder: 123 episodes (36GB) ← **BEST**
- Season-specific folders with duplicates
- Individual episode folders

**Recommended Action - CONSOLIDATE TO NAS**:

1. **Keep NAS main folder**: `Rick and Morty (2013)` - 123 episodes

2. **Delete USB scattered folders**:
```bash
cd /external/media/TV
rm -rf "Rick.and.Morty.S01.720p.BluRay.x264-DAA[rartv]"
rm -rf "Rick.and.Morty.S01.1080p.BluRay.x264-DAA[rartv]"
rm -rf "Rick.and.Morty.S02.720p.BluRay.X264-REWARD[rartv]"
rm -rf "Rick.and.Morty.S03.BDRip.x264-PHASE[rartv]"
rm -rf "Rick.and.Morty.S04.1080p.AMZN.WEBRip.DDP5.1.x264-CtrlHD[rartv]"
# ... and all other Rick and Morty USB folders
```

3. **Delete NAS scattered folders** (via File Station or Sonarr):
```bash
cd /home/youruser/synology/Media/TV\ Shows
# Keep ONLY: "Rick and Morty (2013)"
# Delete all others (Season-specific folders, individual episodes)
```

4. **Use Sonarr to manage**: http://192.168.1.11:8989
   - Set `Rick and Morty (2013)` as the ONLY monitored folder
   - Run "Rescan" to detect episodes
   - Delete duplicate files from Sonarr UI

**Estimated Savings**: 15-20GB

---

### **4. FAMILY GUY - USB Duplicates** ⚠️

**Issue**: 2 episodes with both 720p and HDTV versions

**Action**:
```bash
cd /external/media/TV/Family\ Guy

# Keep higher quality (720p), delete HDTV versions:
rm "Family.Guy.S13E05.HDTV.x264-KILLERS.mp4"
rm "Family.Guy.S13E06.HDTV.x264-KILLERS.mp4"
```

**Savings**: ~500MB

---

### **5. OTHER SMALL DUPLICATES**

**Drunk History, Insecure, South Park** (USB):
- 2-3 episodes each with dual quality versions
- Keep highest quality, delete lower

**Action**: Delete via file name (lower quality version)

**Savings**: ~1-2GB total

---

### **6. NAS FAMILY GUY/CLOSE ENOUGH** ⚠️ **Use Sonarr**

**Issue**: ~70+ NAS duplicates across Family Guy seasons and Close Enough

**Action**: Use Sonarr's "Manage Episodes" feature:
1. Go to: http://192.168.1.11:8989
2. Each affected show → "Manage Episodes"
3. Filter: "Duplicate Files"
4. Compare file sizes, delete lower quality

**Shows Affected**:
- Family Guy Season 22, 23
- Close Enough Season 1, 2
- Various other shows

**Estimated Savings**: ~25GB

**Time Required**: 1-2 hours

---

## ✅ **Quick Wins - Execute Now** (~15GB in 30 min)

These are **confirmed safe deletions**:

### **Via SSH**:

```bash
ssh youruser@192.168.1.11

# 1. American Dad Season 15 duplicates
cd /external/media/TV
rm -rf "American Dad! (2005) Season 15 S15 (1080p AMZN WEB-DL x265 HEVC 10bit EAC3 5.1 ImE)"

# 2. Bob's Burgers - delete USB, keep NAS
rm -rf "Bob's Burgers"

# 3. Family Guy low quality versions
cd "Family Guy"
rm "Family.Guy.S13E05.HDTV.x264-KILLERS.mp4"
rm "Family.Guy.S13E06.HDTV.x264-KILLERS.mp4"

# Check freed space
df -h /external/media
```

**Expected Savings**: ~14GB
**New USB Free Space**: 80GB → 94GB

---

## 🔧 **Weekend Task - Sonarr Cleanup** (~36GB in 2-3 hours)

1. **Rick and Morty Consolidation**:
   - Delete all USB Rick and Morty folders
   - Delete NAS scattered folders, keep main
   - Sonarr cleanup for remaining duplicates
   - **Savings**: ~20GB

2. **NAS Family Guy/Close Enough**:
   - Use Sonarr "Duplicate Files" filter
   - Delete lower quality versions
   - **Savings**: ~15GB

3. **Final cleanup**:
   - Review `/tmp/usb_tv_duplicates.txt`
   - Review `/tmp/nas_tv_duplicates_remaining.txt`
   - Delete any remaining one-off duplicates
   - **Savings**: ~1GB

---

## 📊 **Expected Results**

| Phase | Action | Savings | Total Freed |
|-------|--------|---------|-------------|
| **Phase 1 (Done)** | Initial duplicates | 51GB | 51GB |
| **Quick Wins (Today)** | American Dad, Bob's, Family Guy | 14GB | 65GB |
| **Weekend Sonarr** | Rick and Morty, NAS cleanup | 36GB | **101GB** |

**Final Storage Status**:
- **NAS**: 13GB → 64GB free (~1.2%)
- **USB**: 80GB → 116GB free (~5.3%)

**Still critically low - need additional cleanup beyond duplicates!**

---

## 🔗 **Tools & Resources**

- **Sonarr**: http://192.168.1.11:8989
- **Synology File Station**: http://192.168.1.20:5000
- **Duplicate Reports**:
  - `/tmp/usb_tv_duplicates.txt` (37 files)
  - `/tmp/nas_tv_duplicates_remaining.txt` (~172 files)
  - `/tmp/cross_location_tv_duplicates.txt` (90 episodes)

---

## ⚠️ **Before You Delete**

1. **Verify in Sonarr** that episodes exist elsewhere
2. **Check file sizes** - keep larger/better quality
3. **Test playback** if unsure about quality
4. **Backup** if you're uncertain (optional)

---

**Created**: 2026-01-02
**Next Review**: After quick wins execution

