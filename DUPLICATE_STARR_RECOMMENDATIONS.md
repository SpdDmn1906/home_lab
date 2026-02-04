# Duplicate Cleanup Recommendations for STARR Management

**Date**: January 6, 2026
**Goal**: Fully manage library with STARR apps (Radarr/Sonarr)
**Analysis Based On**: STARR-managed locations, organization, quality, and size

---

## 📊 Summary

### Movies (17 duplicates)
- ✅ **Keep STARR-managed (NAS)**: 13 duplicates
- ⚠️ **Need Review**: 4 duplicates
- 💾 **Potential Space Savings**: 20.91GB

### TV Shows (187 duplicates)
- ✅ **Keep STARR-managed (NAS)**: 154 duplicates
- ✅ **Keep External**: 32 duplicates (better quality/organization)
- ⚠️ **Need Review**: 1 duplicate
- 💾 **Potential Space Savings**: 209.46GB

**Total Potential Savings**: ~230GB

---

## 🎯 STARR Management Principles

### Priority Order (Highest to Lowest)
1. **STARR-Managed Locations** (`/data/media` or `/home/youruser/synology/Media/`)
   - These are actively managed by Radarr/Sonarr
   - Files here are organized, tracked, and automatically updated
   - **KEEP duplicates in these locations**

2. **Proper Organization**
   - Folders: `Movie Name (Year)/file.mkv` format
   - Better naming conventions
   - **KEEP better organized versions**

3. **Quality**
   - Bluray > Web > DVD > Low (CAM/TS)
   - **KEEP higher quality versions**

4. **File Size**
   - Larger files usually better (when quality is same)
   - **KEEP larger files when quality matches**

5. **External/USB Locations**
   - Less managed by STARR apps
   - **DELETE from external when duplicate exists in STARR-managed location**

---

## 🎬 Movie Duplicate Recommendations

### Keep STARR-Managed (13 movies)

**Examples:**
- ✅ **Keep**: `/home/youruser/synology/Media/Movies/Back on the Strip (2023)`
  - ❌ **Delete**: `/home/youruser/synology/Media/Movies/Back On The Strip (2023) [1080p] [BluRay] [5.1] [YTS.MX]`
  - **Reason**: Better organized folder structure

- ✅ **Keep**: `/home/youruser/synology/Media/Movies/Deadpool.2.2018.Super.Duper.Cut.UNRATED.1080p.BluRay.x265-RARBG`
  - ❌ **Delete**: `/home/youruser/synology/Media/Movies/Deadpool.2.2018.Super.Duper.Cut.UNRATED.1080p.10bit.BluRay.8CH.x265.HEVC-PSA`
  - **Reason**: Larger file size, better organization

- ✅ **Keep**: `/home/youruser/synology/Media/Movies - Kids/How to Train Your Dragon 2 (2014)`
  - ❌ **Delete**: `/external/media/Kids Movies/How to Train Your Dragon 2 (2014)`
  - **Reason**: STARR-managed location (NAS) vs external

### Need Review (4 movies)

1. **Kicking & Screaming (2005)**
   - Location 1: `/home/youruser/synology/Media/Movies - Kids/` (1.51GB)
   - Location 2: `/home/youruser/synology/Media/Movies/` (1.51GB)
   - **Decision**: Keep in appropriate category (Kids vs Regular)
   - **Recommendation**: Keep in Kids Movies if it's a kids movie, otherwise move to regular Movies

---

## 📺 TV Show Duplicate Recommendations

### Keep STARR-Managed (154 shows)
Most TV show duplicates should be kept in NAS locations (STARR-managed).

### Keep External (32 shows)
Some external/USB versions are kept because they have:
- Better organization
- Higher quality
- More complete episodes

**Action**: After keeping external version, consider moving to NAS and adding to Sonarr.

### Need Review (1 show)
Check the detailed report for specific show requiring manual review.

---

## 📋 Action Plan

### Phase 1: Movies (Immediate - ~21GB savings)

1. **Review the 4 movies needing manual decision**
   ```bash
   # Check the review items
   grep "REVIEW" /tmp/duplicate_starr_recommendations.txt
   ```

2. **Delete recommended duplicates**
   - All deletions are from STARR-managed locations (safe)
   - Files being deleted are lower quality or less organized
   - **Total savings**: ~21GB

3. **Verify in Radarr**
   - After deletion, trigger Radarr refresh
   - Ensure movies are still tracked correctly

### Phase 2: TV Shows (Immediate - ~209GB savings)

1. **Review the 1 show needing manual decision**

2. **Delete recommended duplicates**
   - Most deletions from external/USB (less managed)
   - Some deletions from NAS (lower quality versions)
   - **Total savings**: ~209GB

3. **Verify in Sonarr**
   - After deletion, trigger Sonarr refresh
   - Ensure shows are still tracked correctly

### Phase 3: Consolidation (Optional)

1. **Move External → NAS**
   - For the 32 external TV shows being kept
   - Move to NAS and add to Sonarr
   - Delete from external after successful move

2. **Update STARR Root Folders**
   - Ensure all root folders point to `/data/media` paths
   - Consolidate to single location per content type

---

## 🔧 Implementation Script

A detailed deletion script can be generated from the recommendations:

```bash
# View recommendations
cat /tmp/duplicate_starr_recommendations.txt

# Generate deletion commands (REVIEW BEFORE RUNNING)
grep "DELETE:" /tmp/duplicate_starr_recommendations.txt | \
  sed 's/❌ DELETE: //' | \
  while read path; do
    echo "# Review: $path"
    echo "rm -rf \"$path\""
  done > /tmp/deletion_commands.sh
```

**⚠️ IMPORTANT**: Review all deletion commands before executing!

---

## ✅ Verification Steps

After deletions:

1. **Trigger STARR Refreshes**
   ```bash
   # Radarr
   curl -X POST -H "X-Api-Key: YOUR_KEY" \
     "http://localhost:7878/api/v3/command" \
     -d '{"name":"RefreshMovie"}'

   # Sonarr
   curl -X POST -H "X-Api-Key: YOUR_KEY" \
     "http://localhost:8989/api/v3/command" \
     -d '{"name":"RefreshSeries"}'
   ```

2. **Check Storage Space**
   ```bash
   df -h /home/youruser/synology
   df -h /external/media
   ```

3. **Verify Plex Libraries**
   - Check Plex for any missing items
   - Trigger library refresh if needed

---

## 📝 Files Generated

- `/tmp/duplicate_starr_recommendations.txt` - Detailed recommendations
- `/tmp/duplicate_movies_report.txt` - All movie duplicates
- `/tmp/duplicate_tv_report.txt` - All TV show duplicates

---

## 🎯 Expected Results

After cleanup:
- ✅ **~230GB freed** across NAS and USB
- ✅ **All duplicates in STARR-managed locations** (easier management)
- ✅ **Better organization** (proper folder structures)
- ✅ **Higher quality files** retained
- ✅ **Fully STARR-managed library** (easier automation)

---

**Next Steps**: Review recommendations file and execute deletions carefully, then trigger STARR refreshes.

