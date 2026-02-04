# File Station Deletion Checklist - Complete Cleanup

**Date**: 2026-01-02
**Reason**: CIFS mount permissions prevent SSH deletion
**Method**: Manual deletion via Synology File Station
**URL**: `http://192.168.1.20:5000`

---

## ⚠️ **IMPORTANT - Read First**

Due to CIFS permissions on your media server, **all NAS deletions must be done through the Synology web interface**.

**Total to Delete**: ~350GB
- 4K Movies: ~58GB
- CAM/TELESYNC: ~31GB
- Harry Potter: 49GB
- From (TV): 49GB
- Planet Earth II 4K: 26GB
- SC Folder: ~7GB
- Family Guy old seasons: ~138GB
- American Dad old seasons: ~18GB

---

## 📝 **Step-by-Step Deletion Guide**

### **1. Access Synology File Station**

1. Open browser: `http://192.168.1.20:5000`
2. Log in with Synology admin credentials
3. Open **File Station** app
4. Navigate to `/Hulk` share

---

### **2. DELETE: 4K/2160p Movies** (~58GB)

**Path**: `/Hulk/Media/Movies`

Delete these **11 folders**:

```
□ Avengers Endgame (2019)[2160p] (5.3GB)
□ Doctor Strange (2016) [2160p] [4K] [BluRay] [5.1] [YTS.MX] (5.4GB)
□ Pacific.Rim.2013.2160p.10bit.HDR.BluRay.8CH.x265.HEVC-PSA (6.6GB)
□ Rogue One A Star Wars Story (2016) [2160p] [4K] [BluRay] [5.1] [YTS.MX] (6.1GB)
□ Solo.A.Star.Wars.Story.2018.4K.HDR.2160p.BDRip Ita Eng x265-NAHOM (5.1GB)
□ Star Wars Episode IX - The Rise Of Skywalker (2019) [2160p] [4K] [BluRay] [5.1] [YTS.MX] (6.6GB)
□ Star.Wars.The.Last.Jedi.2017.4K.UltraHD.BluRay.2160p.x264.TrueHD.Atmos.7.1.AAC.7.1-POOP (2.5GB)
□ The Dark Knight (2008) [2160p] [4K] [BluRay] [5.1] [YTS.MX] (7.6GB)
□ The Dark Knight Rises (2012) [2160p] [4K] [BluRay] [5.1] [YTS.MX] (2.5GB)
□ The Matrix Reloaded (2003) [2160p] [4K] [BluRay] [5.1] [YTS.MX] (6.8GB)
□ Wonder.Woman.1984.2020.HDR.2160p.WEB.H265-NAISU (2.4GB)
```

---

### **3. DELETE: CAM/TELESYNC Movies** (~31GB)

#### **3A. Kids Movies - Poor Quality**

**Path**: `/Hulk/Media/Movies - Kids`

Delete these **7 folders**:

```
□ DC.League.of.Super-Pets.2022.1080p.TELESYNC.x265-iDiOTS (2.0GB)
□ Dog.Man.2025.1080p.TELESYNC.x264.COLLECTiVE (2.8MB)
□ Inside.Out.2.2024.1080p.TELESYNC.x264.COLLECTiVE (2.4GB)
□ Minions.The.Rise.Of.Gru.2022.720p.TELESYNC.x265-iDiOTS (3.9GB)
□ Mufasa - The Lion King (2024) (3.6GB)
□ Plankton The Movie (2025) (4.2GB)
□ Sonic the Hedgehog 3 (2024) (16GB)
```

#### **3B. Main Movies - Poor Quality**

**Path**: `/Hulk/Media/Movies`

Delete these **2 folders**:

```
□ Like.a.Boss.2020.HDCAM.x264.AC3-ETRG (882MB)
□ Monster.Hunter.2020.HDCAM.850MB.c1nem4.x264-SUNSCREEN[TGx] (847MB)
```

---

### **4. DELETE: Harry Potter Collection** (49GB)

**Path**: `/Hulk/Media/Movies`

Delete **1 folder**:

```
□ Harry.Potter.Complete.Collection.2001-2011.1080p.BluRay.x264.DTS-ETRG (49GB)
```

---

### **5. DELETE: TV Shows** (75GB)

#### **5A. From (2022) Series**

**Path**: `/Hulk/Media/TV Shows`

Delete **1 folder**:

```
□ From (2022) (49GB)
```

#### **5B. Planet Earth II 4K**

**Path**: `/Hulk/Media/TV Shows`

Delete **1 folder**:

```
□ Planet.Earth.II.Season.1.S01.2160p.4K.UHD.10bit.HDR.BluRay.AAC.5.1.x265.HEVC-KRISH (26GB)
```

---

### **6. DELETE: Family Guy - Old Seasons** (~138GB)

**Path**: `/Hulk/Media/TV Shows/Family Guy (1999)`

**Issue**: Family Guy has a complex structure. The analysis showed individual season folders but couldn't identify season numbers properly.

**Recommended Action**:

1. Open `/Hulk/Media/TV Shows/Family Guy (1999)`
2. Look for folders named like:
   - `Season 01`, `Season 02`, ..., `Season 12`
   - Or `S01`, `S02`, ..., `S12`
3. **DELETE** all seasons numbered **1-12**
4. **KEEP** seasons numbered **13-22** (and any other recent content)

**If seasons are mixed/hard to identify**:
- Use Sonarr (http://192.168.1.11:8989) to unmonitor Seasons 1-12
- Then delete files via Sonarr's interface (it will show file paths)

**Expected Savings**: ~138GB

---

### **7. DELETE: American Dad - Old Seasons** (~18GB)

**Path**: `/Hulk/Media/TV Shows/American Dad!`

The main "American Dad!" folder has season subfolders. Delete these **4 folders**:

```
□ Season 1 (6.7GB)
□ Season 4 (3.2GB)
□ Season 9 (3.1GB)
□ Season 10 (5.3GB)
```

**KEEP** these folders:
- Season 12, 15, 19, 20, 21 (recent content)

**Expected Savings**: ~18GB

---

### **8. DELETE: SC Folder - Old Files** (~7GB)

**Path**: `/Hulk/SC`

Delete these **4 folders + 4 files**:

#### **Folders**:
```
□ Adobe Lightroom Classic v9.4 + Patch (macOS) (1.4GB)
□ Adobe Photoshop 2021 v22.0.1 Final + Patch (macOS) (3.0GB)
□ Microsoft Office 2019 VL 16.31 FULL MacOS [TheWindowsForum.com] (3.0GB)
□ Office.2019.16.19.macOS (1.7GB)
```

#### **Files**:
```
□ PlexMediaServer-1.21.2.3943-a91458577-armv7hf.spk (93MB)
□ PlexMediaServer-1.21.3.4014-58bd20c02-armv7hf.spk (93MB)
□ PlexMediaServer-1.21.3.4021-5a0a3e4b2-armv7hf.spk (94MB)
□ PlexMediaServer-1.22.1.4275-48e10484b-armv7hf_DSM6.spk (98MB)
```

---

## ✅ **Deletion Summary**

| Category | Items | Space | Priority |
|----------|-------|-------|----------|
| 4K Movies | 11 | 58GB | HIGH |
| CAM/TELESYNC | 9 | 31GB | HIGH |
| Harry Potter | 1 | 49GB | HIGH |
| From (TV) | 1 | 49GB | HIGH |
| Planet Earth II | 1 | 26GB | MEDIUM |
| Family Guy S1-12 | ~100 eps | 138GB | MEDIUM |
| American Dad S1-10 | ~40 eps | 18GB | MEDIUM |
| SC Folder | 8 | 7GB | LOW |
| **TOTAL** | **~130** | **~376GB** | - |

---

## 🎯 **Quick Wins** (Do First - ~214GB in 30 min)

Check these boxes as you delete:

**High Priority Deletions**:
- [ ] All 11 x 4K movies (58GB)
- [ ] All 9 x CAM/TELESYNC movies (31GB)
- [ ] Harry Potter Collection (49GB)
- [ ] From (2022) series (49GB)
- [ ] Planet Earth II 4K (26GB)

**Expected After Quick Wins**: 96GB → 310GB free (5.7%)

---

## 📊 **After Full Cleanup**

**Current**: 96GB free (1.8%)
**After All Deletions**: 472GB free (8.7%)
**Target (15%)**: 810GB free

**Still need**: ~338GB more (consider storage expansion or deeper content audit)

---

## 🔄 **After Deletion - Trigger Radarr/Sonarr**

Once deletions are complete via File Station, trigger searches:

### **Radarr** (http://192.168.1.11:7878):
1. Go to **Library**
2. Click **Refresh All** (top right)
3. Wait for scan to complete (~5 min)
4. For **Harry Potter** specifically:
   - Search each movie individually
   - This time, select **1080p BluRay** quality (not 4K)

### **Sonarr** (http://192.168.1.11:8989):
1. Go to **Series**
2. Find **From (2022)**
3. Click → **Delete Series** (remove from Sonarr)
4. Family Guy & American Dad will auto-detect missing episodes
5. Trigger searches if desired

---

## ⚠️ **IMPORTANT NOTES**

1. **Harry Potter Re-Download**:
   - Previous version: 49GB (1080p)
   - New download should be similar or smaller
   - Use Radarr to ensure quality control

2. **Family Guy/American Dad**:
   - Sonarr makes this easier than manual deletion
   - Use "Unmonitor" feature to prevent re-downloads
   - Or delete files directly and Sonarr will detect

3. **4K Content**:
   - You have **no GPU** for hardware transcoding
   - 4K causes buffering/lag
   - Always prefer 1080p BluRay for best experience

4. **Verify Before Deleting**:
   - Double-check folder names
   - Once deleted from File Station, cannot undo
   - Consider taking screenshots of folder lists

---

**Created**: 2026-01-02
**Est. Time**: 1-2 hours for all deletions
**Next Step**: After deletions, run verification scan (see companion doc)

