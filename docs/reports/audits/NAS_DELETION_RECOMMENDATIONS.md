# NAS Deletion Recommendations - Storage Optimization

**Date**: 2026-01-02
**Current NAS Status**: 5.3TB used / 5.4TB total (99% full - **96GB free**)
**Goal**: Reach 15% free space (~810GB) = **Need to free ~714GB more**

---

## 📊 **Storage Overview**

| Folder | Size | Status | Action Potential |
|--------|------|--------|------------------|
| **Media** | 3.2TB | ✅ Manageable | ~300-400GB can be freed |
| **JC (Janelle)** | 1.8TB | 🔒 **UNTOUCHABLE** | 0GB (reference only) |
| **SC (Personal)** | 41GB | ✅ Can clean | ~39GB can be freed |
| **#recycle** | 72KB | ✅ Negligible | 0GB |

---

## 🎯 **Deletion Recommendations by Priority**

### **TIER 1: Quick & Safe Wins** (~147GB) ⚡

These are safe, immediate deletions with minimal impact:

#### **1A. SC Folder - Old Downloads (32GB)**
```bash
# Via Synology File Station or SSH:
/Hulk/SC/downloads folder 7-2021 (32GB)
```
- **Why**: Downloads from July 2021, likely outdated or already extracted
- **Risk**: LOW - verify nothing critical inside first
- **Savings**: 32GB

#### **1B. SC Folder - Old Software Installers (7GB)**
```bash
/Hulk/SC/Microsoft Office 2019 VL... (3GB)
/Hulk/SC/Adobe Photoshop 2021... (3GB)
/Hulk/SC/Office.2019.16.19.macOS (1.7GB)
/Hulk/SC/Adobe Lightroom Classic v9.4... (1.4GB)
```
- **Why**: Can re-download if needed, taking up space
- **Risk**: VERY LOW - installers are always available
- **Savings**: 7GB

#### **1C. SC Folder - Old Plex Versions (280MB)**
```bash
/Hulk/SC/PlexMediaServer-1.22.1...spk
/Hulk/SC/PlexMediaServer-1.21.3...spk (2 files)
```
- **Why**: Outdated versions, running containers now
- **Risk**: NONE - can download from Plex.tv
- **Savings**: 280MB

#### **1D. Kids Movies - Poor Quality Recent Releases (24GB)**
```bash
/Hulk/Media/Movies - Kids/Sonic the Hedgehog 3 (2024) (16GB)
/Hulk/Media/Movies - Kids/Plankton The Movie (2025) (4.2GB)
/Hulk/Media/Movies - Kids/Mufasa - The Lion King (2024) (3.6GB)
```
- **Why**: Very recent (Dec 2024/Jan 2025), likely CAM/TELESYNC quality
- **Action**: Delete and wait for proper BluRay/WEB-DL releases in 2-3 months
- **Risk**: LOW - kids can wait for better quality
- **Savings**: 24GB

#### **1E. Kids Movies - Low Quality/Old Encodes (8GB)**
```bash
/Hulk/Media/Movies - Kids/Minions.The.Rise.Of.Gru.2022.720p.TELESYNC... (3.9GB)
/Hulk/Media/Movies - Kids/Leo.2023.720p.WEBRip.800MB... (4.2GB)
```
- **Why**: TELESYNC = poor quality, or 720p low-bitrate encodes
- **Action**: Replace with proper 1080p versions or delete if not watched
- **Risk**: LOW
- **Savings**: 8GB

#### **1F. TV Shows - Completed/Watched Content (76GB)**
```bash
/Hulk/Media/TV Shows/From (2022) (49GB)
/Hulk/Media/TV Shows/Shogun 2024... (14GB)
/Hulk/Media/TV Shows/Lioness (12GB)
```
- **Why**: Recent limited series, likely fully watched
- **Action**: Delete if watched and won't rewatch soon
- **Risk**: MEDIUM - check Plex watch status first
- **Savings**: 75GB (if watched)

**TIER 1 TOTAL: ~147GB** (39GB from SC + 32GB from Kids + 76GB from watched shows)

---

### **TIER 2: Content Optimization** (~180GB) 🔄

Requires more thought but significant savings:

#### **2A. 4K Movies → 1080p Downgrade (50GB savings)**

Your server **lacks hardware transcoding** (no GPU), making 4K playback resource-intensive. Consider replacing these with 1080p versions:

| Movie | Current (4K) | 1080p Est. | Savings |
|-------|-------------|------------|---------|
| The Dark Knight (2008) | 7.6GB | ~2.5GB | 5.1GB |
| The Matrix Reloaded (2003) | 6.8GB | ~2GB | 4.8GB |
| Star Wars Ep IX (2019) | 6.6GB | ~2GB | 4.6GB |
| Pacific Rim (2013) | 6.6GB | ~2GB | 4.6GB |
| Rogue One (2016) | 6.1GB | ~1.8GB | 4.3GB |
| Doctor Strange (2016) | 5.4GB | ~1.6GB | 3.8GB |
| Avengers Endgame (2019) | 5.3GB | ~1.8GB | 3.5GB |
| Solo (2018) | 5.1GB | ~1.5GB | 3.6GB |
| + 3 more 4K movies | ~12GB | ~4GB | 8GB |

**Process**:
1. Use Radarr to search for 1080p versions
2. Delete 4K versions after new download completes
3. **Why**: No hardware transcoding = 4K causes buffering/lag
4. **Risk**: MEDIUM - visual quality downgrade (but better playback experience)
5. **Savings**: ~50GB

#### **2B. Movie Collections - Downgrade or Remove (52GB)**

##### **Harry Potter Collection (49GB → 720p 24GB = 25GB savings)**
```bash
/Hulk/Media/Movies/Harry.Potter.Complete.Collection.2001-2011...
```
- **Current**: 8 movies, 1080p BluRay DTS (~6GB each)
- **Option A**: Downgrade to 720p H265 (~3GB each) = 25GB savings
- **Option B**: Keep if frequently watched
- **Risk**: MEDIUM - popular collection

##### **Rocky Saga (14GB)**
```bash
/Hulk/Media/Movies/Rocky Saga (1976-2006)...
```
- **Action**: Delete if rarely watched
- **Risk**: LOW - niche content
- **Savings**: 14GB

##### **Mighty Ducks Trilogy (13GB)**
```bash
/Hulk/Media/Movies/The Mighty Ducks Trilogy (1080p)
```
- **Action**: Downgrade to 720p or delete if not watched
- **Risk**: LOW
- **Savings**: ~7GB (downgrade) or 13GB (delete)

**TIER 2A+2B TOTAL: ~102GB**

#### **2C. TV Shows - Season Pruning (78GB)**

##### **Family Guy (173GB → 90GB = 83GB savings)**
```bash
/Hulk/Media/TV Shows/Family Guy (1999)
```
- **Current**: 173GB (likely 350+ episodes, Seasons 1-22+)
- **Action**: Keep only Seasons 18-22 (recent 5 seasons)
- **Rationale**: Family Guy is episodic, old episodes rarely rewatched
- **Savings**: ~83GB (keep ~90GB of recent content)
- **How**: Use Sonarr → Unmonitor old seasons → Delete files

##### **American Dad (46GB → 26GB = 20GB savings)**
```bash
/Hulk/Media/TV Shows/American Dad!
```
- **Action**: Keep only recent 5-6 seasons
- **Savings**: ~20GB

**TIER 2C TOTAL: ~103GB**

**TIER 2 GRAND TOTAL: ~205GB** (50GB 4K + 52GB collections + 103GB TV pruning)

---

### **TIER 3: Deep Content Review** (~100-150GB) 🔍

Requires watching Plex stats and manual review:

#### **3A. Unwatched Content Audit**

Use Plex to identify:
- Movies **never watched** and **added >6 months ago**
- TV show seasons **never started**
- Duplicate quality versions (we already cleaned cross-duplicates, but check for quality dupes)

**Process**:
1. Plex → Movies → Filter: "Unplayed" + "Date Added"
2. Review and delete unwatched old content
3. **Estimated**: 50-100GB

#### **3B. Kids Content Rotation**

Kids movies grow fast. Consider:
- Delete watched kids movies (kids rarely rewatch except favorites)
- Keep top 20-30 favorites, rotate others
- **Estimated**: 100-150GB can be trimmed

---

## 📊 **Summary Table**

| Tier | Category | Savings | Effort | Risk |
|------|----------|---------|--------|------|
| **1** | Quick Wins | ~147GB | 30 min | LOW |
| **2** | Content Optimization | ~205GB | 3-5 hours | MEDIUM |
| **3** | Deep Review | ~100GB | 5-10 hours | MEDIUM |
| **TOTAL** | | **~452GB** | | |

**After Tier 1+2**: 96GB → 348GB free (**6.4%** - still below 15%)
**After All Tiers**: 96GB → 548GB free (**10.1%** - closer to 15% target)

---

## ⚠️ **Critical Reality Check**

Even if you delete **ALL recommended content (~452GB)**, you'll have:
- **NAS Free Space**: 96GB → 548GB (**10.1%** free)
- **Still below 15% target** (~810GB)

**The JC (Janelle) folder at 1.8TB is the elephant in the room.**

### **Long-Term Solutions**:

1. **Add More Storage**:
   - Upgrade NAS with larger drives
   - External expansion unit
   - Estimated cost: $300-600 for 2-4TB additional

2. **Move Janelle's Content**:
   - If possible, archive infrequently accessed content (photo dumps, old backups)
   - Move to cloud storage (Google Drive, Backblaze)
   - Move to external USB drive

3. **Content Rotation Strategy**:
   - Keep only current season TV shows
   - Archive old movies to external drive
   - Use Plex watched status to auto-prune

---

## ✅ **Recommended Action Plan**

### **This Week: Execute Tier 1** (~147GB)

1. **SC Folder Cleanup** (39GB):
   ```bash
   # Via Synology File Station:
   /Hulk/SC/downloads folder 7-2021 → DELETE
   /Hulk/SC/Microsoft Office 2019... → DELETE
   /Hulk/SC/Adobe Photoshop 2021... → DELETE
   /Hulk/SC/Adobe Lightroom Classic... → DELETE
   /Hulk/SC/Office.2019.16.19.macOS → DELETE
   /Hulk/SC/PlexMediaServer*.spk (all 3) → DELETE
   ```

2. **Kids Movies - Poor Quality** (32GB):
   ```bash
   # Via Radarr or File Station:
   Sonic 3 (2024) → DELETE (wait for BluRay in March 2025)
   Plankton (2025) → DELETE (wait for release)
   Mufasa (2024) → DELETE (wait for release)
   Minions TELESYNC → DELETE (get proper release)
   Leo 720p low-bitrate → DELETE (get 1080p)
   ```

3. **Check Watched TV Shows** (76GB):
   - Plex → Libraries → TV Shows → "From (2022)" → Check watch status
   - If watched, delete via Sonarr
   - Repeat for "Shogun", "Lioness"

**Time**: 1-2 hours
**Savings**: 147GB
**New Free Space**: 96GB → 243GB (4.5%)

---

### **Next Weekend: Execute Tier 2A+2B** (~102GB)

1. **4K → 1080p Replacements**:
   - Use Radarr: Movie → Search → Filter "1080p BluRay"
   - Monitor downloads
   - Delete 4K versions after confirmation

2. **Collections Review**:
   - Decide on Harry Potter (keep or downgrade)
   - Delete Rocky Saga if unwatched
   - Delete/downgrade Mighty Ducks

**Time**: 3-5 hours
**Savings**: 102GB
**New Free Space**: 243GB → 345GB (6.4%)

---

### **Following Weekends: Tier 2C + 3** (~203GB)

1. **TV Shows Season Pruning** (Sonarr):
   - Family Guy: Unmonitor Seasons 1-17
   - American Dad: Unmonitor old seasons
   - Delete files via Sonarr

2. **Unwatched Content Audit**:
   - Use Plex filters
   - Delete old unwatched movies

**Time**: 5-10 hours over 2-3 weekends
**Savings**: 203GB
**New Free Space**: 345GB → 548GB (10.1%)

---

## 🔗 **Tools & Commands**

### **Synology File Station**:
- URL: `http://192.168.1.20:5000`
- Navigate to `/Hulk` share
- Select folders/files → Delete

### **Sonarr/Radarr**:
- Radarr: `http://192.168.1.11:7878`
- Sonarr: `http://192.168.1.11:8989`
- Use "Unmonitor" to prevent re-downloads
- Use "Delete File" to remove from disk

### **Plex Watch Status**:
```bash
# Check watched status via SSH:
ssh youruser@192.168.1.11
# Then check Plex web UI for watched badges
```

---

## 🔒 **JC (Janelle) Folder - Reference Only**

**Total**: 1.8TB (33% of NAS!)

**Breakdown**:
- Family personal: 757GB
- JCP Shoots: 550GB
- Final Cut Pro Library: 120GB
- Transcend Drive backup: 103GB
- Photo dump to transfer: 92GB
- Youtube Videos: 41GB
- Downloads (2021): 51GB
- Screen recordings: 25GB

**Status**: 🔒 **UNTOUCHABLE** per user request

**Note**: This folder alone prevents you from reaching 15% free space. Long-term, consider:
- Cloud archival of photo dumps and old backups
- Compress screen recordings
- Clean up old downloads (2021)

---

**Created**: 2026-01-02
**Next Review**: After Tier 1 execution
**Related Docs**:
- [REMAINING_DUPLICATES_ACTION_PLAN.md](REMAINING_DUPLICATES_ACTION_PLAN.md)
- [COMPREHENSIVE_DUPLICATE_ANALYSIS.md](COMPREHENSIVE_DUPLICATE_ANALYSIS.md)

