# Bazarr Sync Issue - Debugging Report

## Problem
Bazarr is running and connected to Sonarr/Radarr, but:
- ❌ No subtitles are downloading
- ❌ No provider activity in logs
- ❌ Searches complete with "finished" but find nothing

## Root Cause Analysis

### 1. Path Mismatch Detected
**Sonarr/Radarr Configuration:**
- Sonarr root: `/external/Kids TV` (has 91 series)
- Radarr roots: `/external/Kids Movies` + `/external/Movies` (188 movies total)

**Bazarr Mount Points:**
- `/data` → Synology Hulk Media share (~7,364 files)
- `/Movies` → Synology Hulk Media share (same, ~897 folders)
- `/external` → External disk (~29,633 files)

**Issue:** `/Movies` and `/external/Movies` are DIFFERENT directories
- `/Movies` has 897 folders (Synology)
- `/external/Movies` has 188 folders (External disk)

### 2. Sync Status Unknown
- Bazarr connects to Sonarr/Radarr successfully ✅
- But logs show searches finishing with NO provider activity
- This means Bazarr may not have synced any series/movies yet

### 3. Provider Issues
1. **OpenSubtitles** - Daily quota exhausted (21/20 downloads)
2. **Podnapisi** - Persistent connection timeouts
3. **Shooter** - Should work
4. **GreekSubtitles** - Should work
5. **SubCenter** - Should work
6. **SubDL** - Should work

## Immediate Troubleshooting Steps

### Step 1: Verify Bazarr Sync
Go to `http://192.168.1.11:6767`:

1. **Series Tab** - Do you see any series listed?
   - If YES: Series synced ✅
   - If NO: Sync not working ❌

2. **Movies Tab** - Do you see any movies listed?
   - If YES: Movies synced ✅
   - If NO: Sync not working ❌

### Step 2: If Sync is Missing
Try this from your server terminal:
```bash
# Option A: Full Bazarr reset (WARNING: deletes subtitle history)
docker exec bazarr rm /config/db/bazarr.db
docker restart bazarr
```

Or

```bash
# Option B: Force full update from UI
1. Go to Settings → Sonarr
2. Click "Test" button
3. Go to Settings → Radarr
4. Click "Test" button
5. Go to Settings → Tasks
6. Manually trigger "Full update of series" and "Full update of movies"
```

### Step 3: Verify Path Mapping
After sync, pick ANY series/movie and:
1. Click the subtitle icon
2. Click "Browse" or "Search"
3. Check the **History** tab
4. What providers are listed in the search results?

## Expected Behavior
If synced correctly, when you search for subtitles you should see:
- Provider names (Shooter, GreekSubtitles, SubDL, SubCenter)
- Match percentages
- Download options

If you see this → Providers are working ✅
If you see nothing → Providers not being called ❌

## Configuration Verification Needed

### Bazarr Paths
Need to verify:
- Are Sonarr paths visible to Bazarr?
- Are Radarr paths visible to Bazarr?
- Is there a path mapping needed?

### Directory Access
```bash
# From server, check if paths exist in Bazarr container:
docker exec bazarr ls -lh /external/Kids\ TV
docker exec bazarr ls -lh /external/Kids\ Movies
docker exec bazarr ls -lh /external/Movies
```

If these return empty or errors → Path issue
If these return file lists → Paths are OK

## Next Steps

1. **Check Bazarr UI** (http://192.168.1.11:6767):
   - Do Series/Movies tabs show content?

2. **Report back with:**
   - Screenshot or list of what's shown in Series tab
   - Screenshot or list of what's shown in Movies tab
   - Any error messages you see

3. **If nothing shows:**
   - Let's reset the Bazarr database and resync

4. **If content shows but no downloads:**
   - We'll debug the provider search results

---

This is a **Sonarr/Radarr sync issue**, not a provider issue. Once Bazarr has the content indexed properly, subtitle downloads should work.
