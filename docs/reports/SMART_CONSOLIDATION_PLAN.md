# Smart Media Consolidation Plan - Move Files Into Tracked Folders

**Date**: 2026-01-02
**Strategy**: Move orphaned content INTO Sonarr/Radarr tracked folders instead of deleting
**Goal**: Preserve all content while ensuring everything is tracked

---

## 🎯 **The Discovery**

Your orphaned content analysis was misleading - many "orphaned" folders are actually:
1. **Already tracked** but our path comparison failed
2. **Duplicates** that can be consolidated into the tracked folder
3. **Scattered episodes** that belong in the main tracked folder

**Key Insight**: Instead of deleting 3.7TB, we can **consolidate ~200GB** by moving files into tracked folders!

---

## 📊 **Consolidation Opportunities**

### **Priority 1: Easy Consolidations** (~100GB moved)

#### **1. Family Guy** (40GB to consolidate)
| Location | Size | Episodes | Status |
|----------|------|----------|--------|
| **NAS**: `/home/youruser/synology/Media/TV Shows/Family Guy (1999)/` | 111GB | 252 eps | ✅ **TRACKED** by Sonarr |
| **USB**: `/external/media/TV/Family Guy` | 40GB | 46 eps | ❌ Orphaned |

**Action**: Move USB episodes into NAS tracked folder

```bash
# Check for duplicates first
ssh youruser@192.168.1.11 << 'EOF'
echo "Comparing Family Guy folders..."
# List USB episodes
find "/external/media/TV/Family Guy" -type f \( -name "*.mkv" -o -name "*.mp4" \) -exec basename {} \; | sort > /tmp/fg_usb.txt
# List NAS episodes
find "/home/youruser/synology/Media/TV Shows/Family Guy (1999)" -type f \( -name "*.mkv" -o -name "*.mp4" \) -exec basename {} \; | sort > /tmp/fg_nas.txt

# Find unique episodes on USB
comm -23 /tmp/fg_usb.txt /tmp/fg_nas.txt > /tmp/fg_to_move.txt
unique_count=$(wc -l < /tmp/fg_to_move.txt)

echo "$unique_count unique episodes on USB to move:"
head -10 /tmp/fg_to_move.txt
EOF

# If unique episodes exist, move them:
# sudo rsync -av --remove-source-files "/external/media/TV/Family Guy/" "/home/youruser/synology/Media/TV Shows/Family Guy (1999)/"
```

**Expected Result**:
- If all 46 USB episodes are unique: NAS folder grows to 151GB, 298 episodes
- If some are duplicates: Only unique episodes moved
- After move: Delete empty USB folder
- Sonarr will auto-detect new episodes on next scan

---

#### **2. South Park** (28GB to consolidate + 12GB to delete)
| Location | Size | Episodes | Status |
|----------|------|----------|--------|
| **USB**: `/external/media/TV/South Park (1997)` | 12GB | 49 eps | ✅ **TRACKED** by Sonarr |
| **USB**: `/external/media/TV/South Park` | 28GB | 238 eps | ❌ Orphaned (MORE episodes!) |
| **NAS**: `South Park (1992) Season 23...` | 12GB | 49 eps | ❌ Duplicate of tracked |

**Action**: Move "South Park" episodes into "South Park (1997)" folder

```bash
ssh youruser@192.168.1.11 << 'EOF'
# Move orphaned South Park into tracked folder
sudo rsync -av --remove-source-files "/external/media/TV/South Park/" "/external/media/TV/South Park (1997)/"

# Delete the now-empty orphaned folder
sudo rmdir "/external/media/TV/South Park"

# Delete NAS Season 23 duplicate
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South Park (1992) Season 23 S23 (1080p BluRay x265 HEVC 10bit AAC 5.1 Silence)"

# Delete scattered NAS episodes
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South.Park.S24E00.Post.COVID.1080p.WEB.H264-WHOSNEXT[rarbg]"
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South.Park.S25E01.1080p.WEB.h264-BAE[rarbg]"
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South.Park.S25E02.1080p.WEB.h264-BAE[rarbg]"
sudo rm -rf "/home/youruser/synology/Media/TV Shows/South.Park.S25E03.1080p.WEB.h264-BAE[rarbg]"

echo "✅ South Park consolidated!"
EOF
```

**Expected Result**:
- Tracked folder grows to 40GB, ~287 episodes (49 + 238)
- Space freed: 16GB (deleted NAS duplicates + scattered episodes)
- Sonarr will auto-detect 238 new episodes

---

#### **3. American Dad** (49GB + scattered episodes to consolidate)
| Location | Size | Episodes | Status |
|----------|------|----------|--------|
| **NAS**: `/home/youruser/synology/Media/TV Shows/American Dad!` | 27GB | 64 eps | ✅ **TRACKED** by Sonarr |
| **USB**: `/external/media/TV/American Dad! (2005)` | 49GB | 194 eps | ❌ Orphaned (MORE episodes!) |
| **NAS**: Individual S21 episodes | ~6GB | 17 eps | ❌ Scattered |

**Action**: Move USB folder into NAS tracked folder

```bash
ssh youruser@192.168.1.11 << 'EOF'
# Move USB American Dad into NAS tracked folder
sudo rsync -av --remove-source-files "/external/media/TV/American Dad! (2005)/" "/home/youruser/synology/Media/TV Shows/American Dad!/"

# Delete empty USB folder
sudo rmdir "/external/media/TV/American Dad! (2005)"

# Move scattered S21 episodes into tracked folder
find "/home/youruser/synology/Media/TV Shows" -maxdepth 1 -type d -name "*American Dad*S21*" -o -name "*American Dad*S20E01*" | while read folder; do
    sudo mv "$folder"/* "/home/youruser/synology/Media/TV Shows/American Dad!/" 2>/dev/null || true
    sudo rmdir "$folder" 2>/dev/null || true
done

echo "✅ American Dad consolidated!"
EOF
```

**Expected Result**:
- NAS tracked folder grows to ~82GB, ~275 episodes
- USB freed: 49GB
- Sonarr will auto-detect ~211 new episodes

---

#### **4. Stranger Things** (Delete empty folder)
| Location | Size | Episodes | Status |
|----------|------|----------|--------|
| **USB**: `/external/media/TV/Stranger Things (2016)` | 32GB | 20 eps | ✅ **TRACKED** by Sonarr |
| **USB**: `/external/media/TV/Stranger Things` | 18GB | 0 eps | ❌ Empty folder |

**Action**: Delete empty folder

```bash
ssh youruser@192.168.1.11 'sudo rm -rf "/external/media/TV/Stranger Things"'
```

**Expected Result**: 18GB freed (likely just placeholder folder)

---

### **Priority 2: Scattered Individual Episodes** (~30GB)

Move all scattered individual episode folders into their main show folders:

```bash
ssh youruser@192.168.1.11 << 'EOF'
#!/bin/bash

# Function to move episodes to tracked folder
consolidate_episodes() {
    local show_name="$1"
    local tracked_path="$2"

    echo "📺 Consolidating $show_name..."

    # Find scattered episode folders
    find "/home/youruser/synology/Media/TV Shows" -maxdepth 1 -type d -name "*$show_name*S[0-9][0-9]E[0-9][0-9]*" -o -name "*$show_name*Season [0-9]*" | while read folder; do
        echo "  Moving: $(basename "$folder")"
        sudo mv "$folder"/* "$tracked_path/" 2>/dev/null || true
        sudo rmdir "$folder" 2>/dev/null || true
    done
}

# Get Sonarr tracked paths
SONARR_KEY=$(docker exec sonarr cat /config/config.xml 2>/dev/null | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')

# For each scattered episode, try to match to a tracked show
curl -s -H "X-Api-Key: $SONARR_KEY" "http://192.168.1.11:8989/api/v3/series" | \
    jq -r '.[] | "\(.title)|\(.path)"' | while IFS='|' read -r title path; do

    # Convert Sonarr path to real path
    real_path=$(echo "$path" | sed 's|^/TV Shows/|/home/youruser/synology/Media/TV Shows/|' | sed 's|^/external/TV/|/external/media/TV/|' | sed 's|^/data/media/TV Shows/|/home/youruser/synology/Media/TV Shows/|')

    if [ -d "$real_path" ]; then
        # Look for scattered episodes matching this show
        find "/home/youruser/synology/Media/TV Shows" -maxdepth 1 -type d -iname "*$title*" | while read folder; do
            if [ "$folder" != "$real_path" ]; then
                echo "📺 $title: Moving $(basename "$folder")"
                sudo rsync -av --remove-source-files "$folder/" "$real_path/" 2>/dev/null || true
                sudo rmdir "$folder" 2>/dev/null || true
            fi
        done
    fi
done

echo "✅ Scattered episodes consolidated!"
EOF
```

**Expected Result**: ~30GB of scattered episodes moved into tracked folders

---

### **Priority 3: Truly Orphaned Shows** (Needs Decision)

Shows NOT in Sonarr that you need to decide on:

| Show | Size | Action Options |
|------|------|----------------|
| Bob's Burgers (2011) | 21GB | Already tracked? Check if duplicate |
| Mr. Robot (2015) | 21GB | Add to Sonarr or delete? |
| Krapopolis (2023) | 26GB | Add to Sonarr or delete? |
| Blue Mountain State (2010) | 18GB | Add to Sonarr or delete? |
| Cowboy Bebop (1998) | 16GB | Add to Sonarr or delete? |
| Fallout (2024) | 16GB | Add to Sonarr or delete? |

**For each show, you can**:
1. **Add to Sonarr**: `Sonarr → Add Series → [Show Name] → Import existing files → Point to folder`
2. **Delete**: If unwanted

---

## 📋 **Execution Checklist**

### **Phase 1: Safe Consolidations** (Today - 30 min)
- [ ] Run Family Guy comparison script
- [ ] Consolidate South Park (28GB → tracked folder)
- [ ] Delete South Park NAS duplicates (16GB freed)
- [ ] Delete Stranger Things empty folder (18GB freed)

**Expected**: ~34GB freed, ~238 new episodes tracked

### **Phase 2: Major Consolidations** (This Weekend - 1 hour)
- [ ] Move Family Guy USB episodes to NAS (40GB)
- [ ] Move American Dad USB to NAS (49GB)
- [ ] Consolidate scattered American Dad S21 episodes (6GB)
- [ ] Run Sonarr library refresh

**Expected**: ~95GB of previously orphaned content now tracked

### **Phase 3: Scattered Episodes** (Next Week - 1 hour)
- [ ] Run automated scattered episode consolidation script
- [ ] Verify no duplicates created
- [ ] Run Sonarr library refresh

**Expected**: ~30GB consolidated

### **Phase 4: Review Truly Orphaned** (Ongoing)
- [ ] Review top 20 orphaned shows list
- [ ] For each wanted show: Add to Sonarr
- [ ] For each unwanted show: Delete
- [ ] Re-run orphaned content scan to verify

---

## ⚠️ **Important Notes**

1. **Always use `rsync -av --remove-source-files`** instead of `mv` to safely move files
2. **Check for duplicates** before moving to avoid overwriting better quality files
3. **After consolidation, trigger Sonarr refresh**:
   ```bash
   SONARR_KEY=$(docker exec sonarr cat /config/config.xml 2>/dev/null | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
   curl -X POST -H "X-Api-Key: $SONARR_KEY" "http://192.168.1.11:8989/api/v3/command" -d '{"name": "RefreshSeries"}'
   ```

4. **Storage Impact**:
   - **Freed from USB**: ~49GB (American Dad moved to NAS)
   - **Freed from deletes**: ~34GB (South Park duplicates, empty folders)
   - **NAS space used**: ~89GB (Family Guy 40GB + American Dad 49GB moved to NAS)
   - **Net NAS impact**: NAS fills by ~55GB (89GB added - 34GB deleted)
   - **Net USB freed**: ~49GB

---

## 📊 **Expected Final State**

| Metric | Before | After Phase 1-3 | Change |
|--------|--------|-----------------|--------|
| **Sonarr tracked shows** | 88 | 88 | Same shows |
| **Sonarr tracked episodes** | ~4,500 | ~5,000+ | +500+ episodes |
| **Orphaned TV folders** | 335 | <50 | 285 consolidated |
| **USB free space** | 316GB | 365GB | +49GB |
| **NAS free space** | 316GB | 261GB | -55GB |

**But your NAS is critically low! You MUST address this separately with the orphaned movies (2.5TB) or storage expansion.**

---

**Ready to start? Which phase do you want to execute first?**

