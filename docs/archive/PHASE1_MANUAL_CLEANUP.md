# Phase 1 Manual Cleanup - Remaining Files

**Status**: Most folders deleted (~51GB freed), but some files remain due to CIFS mount permissions.

---

## 📋 **Folders That Need Manual Deletion**

These folders still have **98 locked files** that couldn't be deleted via command line due to network mount permissions.

### **Via Synology File Station** (Recommended)

1. **Log in**: http://192.168.1.20:5000
2. **Navigate to**: File Station → Hulk → Media →
3. **Delete these folders**:

#### **TV Shows** (~40GB):
```
/Hulk/Media/TV Shows/Archer (2009) - 30 files remaining
/Hulk/Media/TV Shows/Bob's Burgers - 58 files remaining
/Hulk/Media/TV Shows/Stranger Things (2016) - 1 file remaining
/Hulk/Media/TV Shows/Ahsoka - Season 1 (2023) - 8 files remaining
```

#### **Movies** (~8GB):
```
/Hulk/Media/Movies/Avengers Infinity War (2018)[1080p] - 1 file remaining
/Hulk/Media/Movies/Black Panther Wakanda Forever (2022) - 1 file remaining
```

---

## ✅ **What Was Successfully Deleted**

- Most content in the 6 folders (~51GB freed)
- Only locked files remain (98 files total)
- NAS free space increased from 13GB → 15GB (more once locked files are deleted)

---

## 💡 **Alternative: Delete via Sonarr/Radarr**

### **Sonarr** (for TV shows):
1. Go to: http://192.168.1.11:8989
2. Search for each show
3. Click show → Delete Series → Delete files
   - Archer (2009)
   - Bob's Burgers
   - Stranger Things (2016)
   - Ahsoka - Season 1 (2023)

### **Radarr** (for movies):
1. Go to: http://192.168.1.11:7878
2. Search for each movie
3. Click movie → Delete Movie → Delete files
   - Avengers Infinity War (2018) [1080p version only!]
   - Black Panther Wakanda Forever (2022) [regular version only!]

---

## ⚠️ **IMPORTANT**

When deleting via Sonarr/Radarr:
- For TV shows: Make sure you're deleting the **NAS duplicate version**, not USB!
- For movies: Keep the **4K/BluRay/1080p version**, delete the lower quality one

---

## 📊 **Expected Results After Manual Cleanup**

- **Additional space freed**: ~48GB (the locked files)
- **Total Phase 1 savings**: ~99GB
- **NAS free space**: 13GB → 112GB (2%)

**Note**: This is still critically low! Phase 2 cleanup is mandatory.

