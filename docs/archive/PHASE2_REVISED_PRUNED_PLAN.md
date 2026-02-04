# Phase 2 - Revised Plan with Pruning

**Date**: 2026-01-02
**Goal**: Keep only last 10 seasons per show, consolidate into tracked folders
**User Request**: Don't move episodes that will be deleted anyway

---

## 🎯 **Pruning Strategy: Keep Last 10 Seasons**

Based on current latest seasons:
- **Family Guy**: Latest ~Season 22 → Keep **Seasons 13-22**
- **American Dad**: Latest ~Season 20 → Keep **Seasons 11-20**
- **South Park**: Latest ~Season 28 → Keep **Seasons 19-28** (already pruned 1-9)

---

## 📊 **USB Content Analysis**

### **1. Family Guy USB**

| Season | Episodes | Action |
|--------|----------|--------|
| Season 9 | 20 | ❌ **DELETE** (too old) |
| Season 10 | 23 | ❌ **DELETE** (too old) |
| Season 11 | 4 | ❌ **DELETE** (too old) |
| Season 12 | 5 | ❌ **DELETE** (too old) |
| **Season 13** | **7** | **✅ KEEP & MOVE** |
| **Season 14** | **22** | **✅ KEEP & MOVE** |

**Summary**:
- **Keep**: 29 episodes (Seasons 13-14)
- **Delete**: 52 episodes (Seasons 9-12)
- **USB freed**: ~11GB (delete) + ~5GB (after move) = **~16GB total**

---

### **2. American Dad USB**

| Season | Episodes | Action |
|--------|----------|--------|
| Season 2 | 4 | ❌ **DELETE** |
| Season 3 | 11 | ❌ **DELETE** |
| Season 5 | 6 | ❌ **DELETE** |
| Season 6 | 28 | ❌ **DELETE** |
| Season 7 | 31 | ❌ **DELETE** |
| Season 8 | 14 | ❌ **DELETE** |
| Season 9 | 2 | ❌ **DELETE** |
| **Season 11** | **15** | **✅ KEEP & MOVE** |
| **Season 12** | **11** | **✅ KEEP & MOVE** |
| **Season 13** | **26** | **✅ KEEP & MOVE** |
| **Season 14** | **7** | **✅ KEEP & MOVE** |
| **Season 16** | **11** | **✅ KEEP & MOVE** |
| **Season 17** | **19** | **✅ KEEP & MOVE** |
| **Season 18** | **15** | **✅ KEEP & MOVE** |

**Summary**:
- **Keep**: 104 episodes (Seasons 11-18)
- **Delete**: 96 episodes (Seasons 2-9)
- **USB freed**: ~23GB (delete) + ~26GB (after move) = **~49GB total**

---

## ✅ **Phase 2 Execution Plan**

### **Step 1: Delete Old Seasons**

```bash
# Family Guy - Delete seasons 9-12
find "/external/media/TV/Family Guy" -type f \
  \( -name "*S09E*" -o -name "*S10E*" -o -name "*S11E*" -o -name "*S12E*" \) \
  -delete

# American Dad - Delete seasons 2-9
find "/external/media/TV/American Dad! (2005)" -type f \
  \( -name "*S02E*" -o -name "*S03E*" -o -name "*S05E*" -o -name "*S06E*" -o \
     -name "*S07E*" -o -name "*S08E*" -o -name "*S09E*" \) \
  -delete
```

**Result**: ~34GB freed from USB immediately

---

### **Step 2: Move Remaining Episodes to NAS Tracked Folders**

```bash
# Family Guy - Move seasons 13-14 (29 episodes)
rsync -av --remove-source-files \
  --include="*/" \
  --include="*S13E*.mkv" --include="*S13E*.mp4" \
  --include="*S14E*.mkv" --include="*S14E*.mp4" \
  --exclude="*" \
  "/external/media/TV/Family Guy/" \
  "/home/youruser/synology/Media/TV Shows/Family Guy (1999)/"

# American Dad - Move seasons 11-18 (104 episodes)
rsync -av --remove-source-files \
  --include="*/" \
  --include="*S11E*.mkv" --include="*S11E*.mp4" \
  --include="*S12E*.mkv" --include="*S12E*.mp4" \
  --include="*S13E*.mkv" --include="*S13E*.mp4" \
  --include="*S14E*.mkv" --include="*S14E*.mp4" \
  --include="*S16E*.mkv" --include="*S16E*.mp4" \
  --include="*S17E*.mkv" --include="*S17E*.mp4" \
  --include="*S18E*.mkv" --include="*S18E*.mp4" \
  --exclude="*" \
  "/external/media/TV/American Dad! (2005)/" \
  "/home/youruser/synology/Media/TV Shows/American Dad!/"
```

**Result**: 133 episodes moved to NAS tracked folders

---

### **Step 3: Cleanup Empty Folders**

```bash
# Remove empty folders after moves/deletes
find "/external/media/TV/Family Guy" -type d -empty -delete
find "/external/media/TV/American Dad! (2005)" -type d -empty -delete
```

---

### **Step 4: Consolidate Scattered Episodes on NAS**

Move scattered American Dad Season 21 episodes into the main tracked folder:

```bash
# Find and move scattered American Dad episodes
find "/home/youruser/synology/Media/TV Shows" -maxdepth 1 -type d \
  \( -name "*American Dad*S2*" -o -name "*American.Dad*S2*" \) | \
  while read folder; do
    rsync -av --remove-source-files "$folder/" "/home/youruser/synology/Media/TV Shows/American Dad!/"
    rmdir "$folder" 2>/dev/null || true
  done
```

---

### **Step 5: Trigger Sonarr Refresh**

```bash
SONARR_KEY=$(docker exec sonarr cat /config/config.xml 2>/dev/null | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
curl -X POST -H "X-Api-Key: $SONARR_KEY" "http://192.168.1.11:8989/api/v3/command" -d '{"name": "RefreshSeries"}'
```

---

## 📊 **Expected Results**

### **Storage Impact:**

| Location | Before | Deleted | Moved to NAS | After | Change |
|----------|--------|---------|--------------|-------|--------|
| **USB** | 78GB free | +34GB | +31GB | **143GB free** | +65GB |
| **NAS** | 392GB free | - | -31GB | **361GB free** | -31GB |

### **Sonarr Impact:**

| Show | Before | After Phase 2 | New Episodes |
|------|--------|---------------|--------------|
| **Family Guy** | 252 eps | 281 eps | +29 |
| **American Dad** | 64 eps | 168 eps | +104 |
| **South Park** | 287 eps | 287 eps | (done in Phase 1) |
| **Total** | - | - | **+133 episodes** |

---

## 🎯 **Why This Approach?**

1. **Respects pruning goals**: Only keeps last 10 seasons per show
2. **Frees USB space**: ~65GB total freed
3. **Everything tracked**: All kept content goes into Sonarr-tracked folders
4. **Efficient**: Delete old seasons first, then move only what's needed

---

## ⚠️ **Critical Note**

After Phase 2:
- **USB**: 143GB free (93% → 93.5% full)
- **NAS**: 361GB free (93% → 93.5% full)

**Storage is still critically low!** The 1,098 orphaned movies (~2.5TB) remain the biggest issue.

---

## 📋 **Ready to Execute?**

This revised plan will:
1. Delete 148 old episodes (Seasons 9-12 of Family Guy, Seasons 2-9 of American Dad)
2. Move 133 recent episodes to NAS tracked folders
3. Free ~65GB from USB
4. Add 133 new episodes to Sonarr tracking

**Would you like me to execute this revised Phase 2 plan?**

