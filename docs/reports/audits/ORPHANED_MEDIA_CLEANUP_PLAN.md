# Orphaned Media Cleanup Plan - Radarr/Sonarr Alignment

**Date**: 2026-01-02
**Issue**: Massive amount of media on disk that Radarr/Sonarr aren't tracking
**Total Orphaned**: ~3.7TB (1,098 movies + 335 TV shows)

---

## 🎯 **The Problem**

Your media exists in **multiple folders with different names**, causing Radarr/Sonarr to only track ONE folder while ignoring the others.

### **Example - South Park:**
| Location | Content | Tracked by Sonarr? |
|----------|---------|-------------------|
| NAS: `South Park (1992) Season 23...` | 48 episodes (Season 23) | ✅ **YES** |
| USB: `South Park` | 266 episodes (Seasons 1-26) | ❌ **NO** |
| NAS: Individual episode folders | 4 episodes (S24-S25) | ❌ **NO** |

**Result**: Sonarr only sees 48 episodes, but you have **318 total episodes** scattered across 6 locations!

---

## 📊 **Orphaned Content Summary**

### **Movies** (~2.5TB orphaned):
- **Radarr tracking**: 1,345 movies
- **On disk**: 2,443 total movie folders (1,098 NOT in Radarr!)
- **Top orphaned**:
  - Rocky Saga (14GB)
  - Mighty Ducks Trilogy (13GB)
  - Dune (2021) (11GB)
  - Cast Away, Don't Look Up (~8GB each)
  - + 1,093 more

### **TV Shows** (~1.3TB orphaned):
- **Sonarr tracking**: 88 TV shows
- **On disk**: 423 total TV show folders (335 NOT in Sonarr!)
- **Top orphaned**:
  - Family Guy - 151GB total (2 folders: 111GB + 40GB)
  - American Dad - 76GB total (2 folders: 49GB + 27GB)
  - Rick and Morty - 36GB (1 main folder orphaned)
  - South Park - 28GB (USB version)
  - Stranger Things - 50GB total (2 folders: 32GB + 18GB)
  - + 330 more

---

## 🎯 **Strategy 1: Consolidate Duplicates** (Recommended)

For shows with multiple folders, consolidate into ONE folder that Sonarr tracks:

### **Family Guy** (151GB total):
| Folder | Size | Episodes | Action |
|--------|------|----------|--------|
| `Family Guy (1999)` | 111GB | ~300 eps | Keep? (more episodes) |
| `Family Guy` | 40GB | ~100 eps | Delete or merge |

**Decision needed**: Which folder has better quality/more complete content?

### **American Dad** (76GB total):
| Folder | Size | Episodes | Action |
|--------|------|----------|--------|
| `American Dad! (2005)` | 49GB | ~150 eps | Keep? |
| `American Dad!` | 27GB | ~80 eps | Delete or merge |

### **South Park** (40GB total):
| Folder | Size | Episodes | Action |
|--------|------|----------|--------|
| USB: `South Park` | 28GB | 266 eps | **KEEP - Most complete!** |
| NAS: Season 23 folder | 12GB | 48 eps | Delete (subset of USB) |
| NAS: Individual episodes | ~3GB | 4 eps | Delete or merge |

**Recommendation**: Keep USB version (266 episodes), delete NAS versions

### **Stranger Things** (50GB total):
| Folder | Size | Episodes | Action |
|--------|------|----------|--------|
| `Stranger Things (2016)` | 32GB | ~20 eps | Keep? |
| `Stranger Things` | 18GB | ~10 eps | Delete (subset) |

---

## 🎯 **Strategy 2: Delete All Orphaned** (Fastest)

If you want Radarr/Sonarr to be the **source of truth**, delete everything they're not tracking:

**Impact**:
- **Movies**: Delete 1,098 folders (~2.5TB)
- **TV Shows**: Delete 335 folders (~1.3TB)
- **Total freed**: ~3.8TB

**Pros**:
- Clean slate
- Everything managed by Radarr/Sonarr
- Easy to maintain

**Cons**:
- Lose ~1,098 movies
- Lose ~335 TV shows
- Would need to re-download if wanted

---

## 🎯 **Strategy 3: Add Orphaned to Radarr/Sonarr** (Most work)

Add all orphaned content to Radarr/Sonarr:

**Process**:
1. For each orphaned folder, add to Radarr/Sonarr
2. Point to existing location
3. Let it rescan and organize

**Pros**:
- Keep all content
- Everything gets tracked

**Cons**:
- Time-consuming (1,433 items to add!)
- May require manual intervention for naming
- Radarr/Sonarr might try to reorganize/rename

---

## ✅ **Recommended Action Plan**

### **Phase 1: Consolidate Duplicates** (This Weekend - ~200GB)

These are shows with multiple folders where one is clearly a subset:

```bash
# SSH to server
ssh youruser@192.168.1.11

# South Park - Keep USB (266 eps), delete NAS versions
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South Park (1992) Season 23 S23 (1080p BluRay x265 HEVC 10bit AAC 5.1 Silence)"
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South.Park.S24E00.Post.COVID.1080p.WEB.H264-WHOSNEXT[rarbg]"
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South.Park.S25E01.1080p.WEB.h264-BAE[rarbg]"
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South.Park.S25E02.1080p.WEB.h264-BAE[rarbg]"
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South.Park.S25E03.1080p.WEB.h264-BAE[rarbg]"

# Then add USB South Park to Sonarr:
# Sonarr → Add Series → South Park → Point to: /external/media/TV/South Park
```

**Savings**: ~16GB

### **Phase 2: Review Top 20 Orphaned Shows** (Manual review)

Review these large orphaned shows to decide keep vs. delete:
1. Family Guy (151GB) - 2 folders
2. American Dad (76GB) - 2 folders
3. Rick and Morty (36GB)
4. Stranger Things (50GB) - 2 folders
5. Bob's Burgers (21GB)
6. Mr. Robot (21GB)
7. Elementary (19GB + 17GB) - 2 folders
8. Blue Mountain State (18GB)
9. Fallout (16GB)
10. Cowboy Bebop (16GB)

**Process**: For each, decide:
- Add to Sonarr? (if wanted)
- Delete? (if unwanted or duplicate)

### **Phase 3: Bulk Delete Orphaned Movies** (Optional - ~2.5TB)

If you want Radarr to be source of truth for movies:

**High-value deletions** (top 100 largest):
- Rocky Saga, Mighty Ducks, Dune, etc. (~500GB for top 100)

**Or delete ALL orphaned movies**: ~2.5TB

---

## 📝 **Files Generated**

**On Server**:
- `/tmp/orphaned_movies.txt` - 1,098 movies not in Radarr
- `/tmp/orphaned_tv.txt` - 335 TV shows not in Sonarr
- `/tmp/radarr_movies.txt` - All movies Radarr is tracking
- `/tmp/sonarr_shows.txt` - All TV shows Sonarr is tracking

**Analysis Scripts**:
```bash
# View top 50 orphaned movies by size
sort -rh /tmp/orphaned_movies.txt | head -50

# View top 50 orphaned TV shows by size
sort -rh /tmp/orphaned_tv.txt | head -50

# Count total orphaned size
awk -F'|' '{print $1}' /tmp/orphaned_movies.txt | numfmt --from=iec | awk '{sum+=$1} END {print sum/1024/1024/1024 " GB"}'
```

---

## 🚨 **Critical Decision Needed**

**You have 3.8TB of orphaned content**. You need to decide:

1. **Keep & Add to Radarr/Sonarr?** (Most work, keep everything)
2. **Consolidate duplicates only?** (Keep unique, merge/delete duplicates ~200GB)
3. **Delete all orphaned?** (Fastest, free ~3.8TB, rely on Radarr/Sonarr)

**My Recommendation**:
- **Phase 1**: Consolidate obvious duplicates (South Park, Family Guy, American Dad, etc.) → ~200GB
- **Phase 2**: Review top 50 largest orphaned items, add wanted ones to Radarr/Sonarr → varies
- **Phase 3**: Bulk delete remaining unwanted orphaned content → ~2-3TB

This gives you control over what to keep while making massive space gains.

---

**What do you want to do first?**

1. Start with South Park consolidation (easy win)?
2. Generate detailed lists of all duplicates for review?
3. Delete all orphaned content (nuclear option)?

Let me know and I'll provide the exact commands!

