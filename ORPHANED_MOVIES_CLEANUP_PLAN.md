# Orphaned Movies Cleanup Plan

**Date**: 2026-01-03
**Total Orphaned**: 120 movies (~279GB)
**Strategy**: Delete unwanted, add wanted to Radarr

---

## 📊 **Complete Breakdown**

| Location | Orphaned | Size | Action |
|----------|----------|------|--------|
| **NAS Movies** | 59 movies | ~106GB | Review & categorize |
| **NAS Kids** | 22 movies | ~38GB | Review & categorize |
| **USB Movies** | 26 movies | ~58GB | Review & categorize |
| **USB Kids** | 13 movies | ~77GB | Review & categorize |

---

## 🗑️ **Category 1: DELETE IMMEDIATELY** (~111GB)

### **1.1 Collections/Multi-Movie Packs** (~93GB)
**Reason**: Radarr manages individual movies, not packs

**Delete List**:
- `Rocky Saga (1976-2006)` - 14GB
- `The Mighty Ducks Trilogy` - 13GB
- `Ice Age - 5 Movie Collection` - 15GB (USB Kids)
- `Despicable Me - Minions 4 Movie Collection` - 15GB (USB Kids)
- `Shrek 1, 2, 3, 4 - Collection` - 12GB (USB Kids)
- `Frozen Collection By Kira` - 3.1GB
- `Madagascar Trilogy 1-3` - 3.4GB (USB Kids)
- `The Raid Collection` - 3.7GB
- `Hot Tub Time Machine 1, 2` - 3.2GB
- `The Transporter Complete 4 Movie Collection` - 2.7GB
- `Lara Croft Tomb Raider 3 Movies Collection` - 2.4GB
- `Zombieland Dilogy` - 2.3GB
- `Ted.2024.S01.COMPLETE` - 2.1GB (TV series, not movie)
- `Back to the Future Trilogy` - 0 (empty)
- `Bruce Lee The Ultimate Collection` - 0 (empty)

### **1.2 4K/2160p Movies** (~18.5GB)
**Reason**: No GPU for 4K transcoding

**Delete List**:
- `Moana.2016.2160p.UHD.BluRay` - 15GB (USB Kids)
- `Frozen II (2019) [2160p] [4K]` - 3.5GB (USB Kids)

### **1.3 Empty/Placeholder Folders** (~0GB)
**Reason**: No actual content (< 1MB)

**Delete List** (many recent movies are just empty placeholders):
- Everything Everywhere All at Once (8KB)
- Fast X (8KB)
- Meg 2 The Trench (8KB)
- Austin Powers International Man (8KB)
- 16 Blocks (96KB)
- Black Panther Wakanda Forever (56KB)
- Back On The Strip (56KB)
- Baywatch (104KB)
- Mission Impossible (120KB)
- Terminator 3 (128KB)
- Wrath of Man (128KB)
- Tron Legacy (168KB)
- Memory (200KB)
- Mortal Kombat (204KB)
- Judas and the Black Messiah (276KB)
- The High Note (340KB)
- No Time To Die (560KB)

**Total Category 1**: ~111GB to delete

---

## ✅ **Category 2: ADD TO RADARR** (~60GB wanted content)

### **2.1 Recent Popular Movies with Files**

**These have actual content and should be added to Radarr**:

| Title | Year | Size | Location |
|-------|------|------|----------|
| **Dune** | 2021 | 11GB | NAS Movies |
| **Aquaman** | 2018 | 7GB | NAS Movies |
| **Avengers Infinity War** | 2018 | 5.4GB | NAS Movies |
| **Pinocchio** | 2022 | 3.6GB | NAS Kids |
| **Elio** | 2025 | 2.8GB | NAS Movies |
| **DC League of Super-Pets** | 2022 | 2.1GB | NAS Kids |
| **Pinocchio** (duplicate) | 2022 | 2.1GB | NAS Kids |
| **Thor Love and Thunder** | 2022 | 1.5GB | NAS Movies |
| **The Kings Man** | 2021 | 1.3GB | NAS Movies |

**Action**: Use Radarr's "Add Movie" → "Import Existing" to add these

### **2.2 Wanted Classics/Older Movies**

**Review these and add wanted ones**:
- Mighty Morphin Power Rangers (1995) - 1.8GB
- Menace II Society (1993) - 1.8GB
- Jobs (2013) - 2GB
- Jay And Silent Bob Reboot (2019) - 1.9GB
- Waiting (2005) - 1.5GB
- Third World Cop (1999) - 1.4GB

---

## 📋 **Category 3: REVIEW & DECIDE** (~108GB)

### **USB Movies** (~58GB)

**Top items requiring decision**:
- Poker Face (2022) - 5GB
- Gods of Egypt (2016) - 3.3GB
- Glass Onion (2022) - 2.7GB
- Guardians of the Galaxy Vol 2 (2017) - 2.7GB
- Everything Everywhere All At Once (2022) - 2.7GB
- Nope (2022) - 2.5GB
- Emancipation (2022) - 2.6GB
- Ghosted (2023) - 2.3GB
- Violent Night (2022) - 2.2GB
- Operation Fortune (2023) - 2.2GB
- The Lion King (2019) - 2.3GB

**Recommendation**: Most of these are recent popular movies - add to Radarr

### **USB Kids** (~4GB remaining after collections deleted)

After deleting the 4 collections (57GB), only ~4GB of singles remain:
- Sherlock Gnomes (2018) - 4.4GB

**Recommendation**: Add to Radarr if wanted, otherwise delete

### **NAS Movies** (remaining ~32GB)

After deletions, review individually in Radarr UI

---

## 🚀 **Execution Plan**

### **Phase 1: Delete Collections & 4K** (~111GB)

```bash
# Collections
sudo rm -rf "/home/youruser/synology/Media/Movies/Rocky Saga (1976-2006) 1080p H265 AC3 5.1 ITA.ENG sub ita.eng Sp33dy94-MIRCrew"
sudo rm -rf "/home/youruser/synology/Media/Movies/The Mighty Ducks Trilogy (1080p)"
sudo rm -rf "/external/media/Kids Movies/Ice Age - 5 Movie Collection (2002-2016) ~ TombDoc"
sudo rm -rf "/external/media/Kids Movies/Despicable Me - Minions 4 Movie Collection (2010-2017) ~ TombDoc"
sudo rm -rf "/external/media/Kids Movies/Shrek 1, 2, 3, 4 - Collection 2001-2010 Eng Fre Ita Spa Multi-Subs [H264-mp4]"
sudo rm -rf "/home/youruser/synology/Media/Movies - Kids/Frozen Collection By Kira [SEV]"
sudo rm -rf "/external/media/Kids Movies/Madagascar Trilogy 1-3 2005-2012 BluRay 720p x264 aac jbr"
sudo rm -rf "/home/youruser/synology/Media/Movies/The Raid Collection (2011-2014) Unrated ~ TombDoc"
sudo rm -rf "/home/youruser/synology/Media/Movies/Hot Tub Time Machine 1, 2 - Unrated 2010-2015 Eng Subs 1080p [H264-mp4]"
sudo rm -rf "/home/youruser/synology/Media/Movies/The Transporter Complete 4 Movie Collection - Action 2002-2015 Eng Subs 1080p [H264-mp4]"
sudo rm -rf "/home/youruser/synology/Media/Movies/Lara Croft Tomb Raider 3 Movies Collection (2001-2018) Dual Audio Hindi KartiKing"
sudo rm -rf "/home/youruser/synology/Media/Movies/Zombieland Dilogy.2009-2019.BDRip.x264.1280x"
sudo rm -rf "/home/youruser/synology/Media/Movies/Ted.2024.S01.COMPLETE.720p.PCOK.WEBRip.x264-GalaxyTV[TGx]"
sudo rm -rf "/home/youruser/synology/Media/Movies/Back to the Future.Trilogy.1080p.BluRay.x264.AC3-RPG"
sudo rm -rf "/home/youruser/synology/Media/Movies/Bruce Lee The Ultimate Collection 1971-1981 1080p HighCode"

# 4K Movies
sudo rm -rf "/external/media/Kids Movies/Moana.2016.2160p.UHD.BluRay.x265-AViATOR"
sudo rm -rf "/external/media/Kids Movies/Frozen II (2019) [2160p] [4K] [BluRay] [5.1] [YTS.MX]"
```

**Expected Result**: ~111GB freed (NAS: +33GB, USB: +78GB)

### **Phase 2: Delete Empty Placeholders** (~0GB but cleaner)

```bash
# Find and delete all folders < 1MB
find /home/youruser/synology/Media/Movies -maxdepth 1 -type d -size -1M -exec sudo rm -rf {} \;
```

### **Phase 3: Add Wanted Movies to Radarr** (Manual)

1. Access Radarr: `http://192.168.1.11:7878`
2. For each wanted movie:
   - Click "Add Movie"
   - Search for the title
   - Click "Add Movie" → "Add Existing Movie"
   - Point to the folder path
   - Set quality profile
   - Click "Add"

**Priority adds**:
- Dune (2021) - 11GB
- Aquaman (2018) - 7GB
- Avengers Infinity War (2018) - 5.4GB
- All recent USB movies (Glass Onion, Guardians 2, etc.)

### **Phase 4: Review & Clean Remaining** (Optional)

Review remaining orphaned movies in Radarr UI and decide individually

---

## 📊 **Expected Results**

| Metric | Before | After Phase 1 | After Phase 3 |
|--------|--------|---------------|---------------|
| **Orphaned movies** | 120 | ~90 | ~30 |
| **Orphaned size** | 279GB | 168GB | ~100GB |
| **USB freed** | - | +78GB | +78GB |
| **NAS freed** | - | +33GB | +33GB |
| **Radarr tracking** | 1,153 | 1,153 | ~1,200 |

---

## ⚠️ **Important Notes**

1. **Collections**: If you want individual movies from a collection, add them to Radarr FIRST, then delete the collection
2. **4K Movies**: Only delete if you're sure - no GPU means 4K won't play smoothly
3. **Empty Folders**: Many "recent" movies are just empty placeholders from failed downloads
4. **USB Kids**: After deleting 4 collections (57GB), you'll free significant space

---

**Ready to execute? Which phase would you like to start with?**

1. Phase 1: Delete collections & 4K (~111GB)
2. Phase 3: Add wanted movies to Radarr first
3. Both: Add wanted, then delete unwanted

Let me know! 🚀

