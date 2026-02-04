# Phase 2: Manual Review & Cleanup Guide

**Estimated Savings**: ~50GB
**Time Required**: 1-2 hours
**Method**: Mix of File Station deletion + Sonarr cleanup

---

## ✅ **Quick Wins - Delete These Now** (~10GB)

These folders are confirmed safe to delete (empty or lower quality):

### **Via Synology File Station** (http://192.168.1.20:5000):

```
/Hulk/Media/TV Shows/Fallout - Season 1 (2024)
└─ Delete this (8 episodes, 4.4GB)
└─ Keep: "Fallout (2024)" - has 11 episodes

/Hulk/Media/Movies/Inception (2010) [1080p]
└─ Delete this (140K - appears to be empty/metadata only)
└─ Keep: "Inception (2010)" - has actual 1.9GB file

/Hulk/Media/Movies/The Terminator (1984) [1080p]
└─ Delete this (128K - empty)
└─ Keep: "The Terminator (1984)" - has actual 2.1GB file

/Hulk/Media/Movies/The To Do List (2013) [1080p]
└─ Delete this (128K - empty)
└─ Keep: "The To Do List (2013)" - has actual 4.6GB file

/Hulk/Media/TV Shows/Rick and Morty S07E01 How Poopy Got His Poop Back...
└─ Delete this (1.6GB - duplicate single episode)
└─ Main folder "Rick and Morty (2013)" has full 123 episodes
```

**Total Savings**: ~10.5GB

---

## 🔧 **Sonarr Cleanup Required** (~30-40GB potential)

### **1. Rick and Morty** (Priority: HIGH)

**Issue**: 35+ duplicate episodes scattered across folders
**Current**: Main folder has 123 episodes (36GB) + rogue S07E01 folder (1.6GB)

**Steps**:
1. Go to Sonarr: http://192.168.1.11:8989
2. Search: "Rick and Morty"
3. Click: "Manage Episodes"
4. Look for episodes showing **duplicate files**
5. For each duplicate:
   - Compare file sizes/quality
   - Keep larger/better quality
   - Delete lower quality via Sonarr
6. After cleanup, delete the rogue "Rick and Morty S07E01..." folder via File Station

**Estimated Savings**: 15-20GB

---

### **2. Bob's Burgers** (Priority: MEDIUM)

**Issue**: Two folders with different episode sets
**Current**:
- `Bob's Burgers`: 57 episodes (30GB) - larger files, lower episode count
- `Bob's Burgers (2011)`: 105 episodes (21G) - smaller files, more episodes

**Analysis**:
- `Bob's Burgers`: ~526MB/episode (better quality?)
- `Bob's Burgers (2011)`: ~200MB/episode (lower quality/720p?)

**Steps**:
1. In Sonarr, search "Bob's Burgers"
2. Check which folder Sonarr is monitoring
3. Compare episode lists:
   - Are there overlaps?
   - Does one folder have unique episodes?
4. **Recommendation**:
   - If significant overlap exists with different quality → keep higher quality, merge unique episodes
   - If mostly unique episodes → keep both, but remove true duplicates only

**Estimated Savings**: 10-15GB (after removing duplicates)

**⚠️ WARNING**: Don't blindly delete one folder - you may lose unique episodes!

---

### **3. Family Guy** (Priority: LOW)

**Issue**: 12 duplicate episodes within 395 total (173GB)
**Current**: Single folder with scattered duplicates

**Steps**:
1. In Sonarr: http://192.168.1.11:8989 → "Family Guy"
2. "Manage Episodes"
3. Filter: "Duplicate Files"
4. For each duplicate:
   - Compare quality (check file size)
   - Delete lower quality version

**Estimated Savings**: 5-10GB

---

## 📊 **Detailed Analysis: Bob's Burgers**

Need to determine if these are truly duplicates or different content:

```bash
# Run this to see episode breakdown:
ssh youruser@192.168.1.11 'bash' << 'EOF'
cd "/home/youruser/synology/Media/TV Shows"

echo "Bob's Burgers folder episodes:"
find "Bob's Burgers" -name "*.mkv" -o -name "*.mp4" | \
    sed 's/.*S\([0-9]\+\)E\([0-9]\+\).*/S\1E\2/' | sort -u | head -20

echo ""
echo "Bob's Burgers (2011) folder episodes:"
find "Bob's Burgers (2011)" -name "*.mkv" -o -name "*.mp4" | \
    sed 's/.*S\([0-9]\+\)E\([0-9]\+\).*/S\1E\2/' | sort -u | head -20
EOF
```

This will show you if there's episode overlap.

---

## 🎯 **Recommended Order of Operations**

### **Today** (30 minutes):
1. ✅ Delete quick wins via File Station (10.5GB)
2. ✅ Delete Rick and Morty rogue folder (1.6GB)
3. ✅ Manual deletion of Phase 1 remaining files (48GB)

**Total freed so far**: ~60GB
**NAS status**: 13GB → 73GB free

### **This Weekend** (1-2 hours):
4. 🔧 Rick and Morty Sonarr cleanup (15-20GB)
5. 🔧 Bob's Burgers analysis and cleanup (10-15GB)
6. 🔧 Family Guy duplicate cleanup (5-10GB)

**Total potential**: ~110GB freed
**Final NAS status**: 13GB → 123GB free (~2.3%)

---

## ⚠️ **Critical Reminder**

Even after freeing **110GB**, your NAS will still be **97.7% full**.

**You MUST**:
1. Delete additional unwatched/old content
2. Or expand NAS storage capacity
3. Target: 15% free (810GB) to prevent corruption

**Options**:
- Delete old TV seasons you've watched
- Remove low-rated movies (check Plex watch history)
- Move some content to external storage
- Add drives to NAS

---

## 📝 **Tracking Progress**

- [ ] Phase 1 manual cleanup (Synology File Station) - 48GB
- [ ] Quick wins deletion - 10.5GB
- [ ] Rick and Morty cleanup - 15-20GB
- [ ] Bob's Burgers cleanup - 10-15GB
- [ ] Family Guy cleanup - 5-10GB

**Running total**: 88-103GB freed

---

## 🔗 **Quick Links**

- **Synology NAS**: http://192.168.1.20:5000
- **Sonarr**: http://192.168.1.11:8989
- **Radarr**: http://192.168.1.11:7878
- **Plex**: http://192.168.1.11:32400

---

**Created**: 2026-01-02
**Next Update**: After Phase 2 completion

