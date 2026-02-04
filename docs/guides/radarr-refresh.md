# Radarr Refresh & Scan Guide

**Date**: January 3, 2026
**Purpose**: How to trigger library refreshes and disk scans in Radarr

---

## 🎯 **Quick Answer**

There is **NO** refresh button in **Settings → Media Management**.

That page only has **automatic scan settings**, not manual triggers.

---

## 📍 **Where to Find Refresh Options**

### **Method 1: System → Tasks** ⭐ **RECOMMENDED**

This is the main place to manually trigger scans:

1. **Open Radarr**: http://192.168.1.11:7878
2. **Go to**: System → Tasks (or click the calendar icon ⚙️)
3. **Find these tasks**:
   - **Refresh Movies** - Updates metadata from TMDb/IMDb APIs
   - **Rescan Disk** - Scans your storage folders for file changes
4. **Click the ▶️ icon** next to each task to run immediately

**When to use:**
- After deleting files (to detect missing movies)
- After adding new files to disk
- After changing monitoring status

**Expected time**: 2-5 minutes

---

### **Method 2: Movies Page (Bulk Actions)**

For refreshing multiple specific movies:

1. **Go to**: Movies page
2. **Select movies**: Check the boxes next to movies
3. **Click "Edit"** at the top
4. **Actions available**:
   - Refresh & Scan
   - Search for missing
   - Change monitoring

**When to use:**
- Refreshing specific movies after changes
- Bulk monitoring changes

---

### **Method 3: Individual Movie Page**

For a single movie:

1. **Click on a movie** to open its details page
2. **Click the ⚙️ gear icon** or **"..." menu** (top right)
3. **Select "Refresh & Scan"**

**When to use:**
- Single movie issues
- Checking specific file status
- After manually copying a file

---

### **Method 4: Terminal/API** ⭐ **FASTEST**

If browser access isn't working or you want automation:

```bash
cd /Users/StephenChung/Documents/Personal/home_lab
./scripts/radarr_quick_refresh.sh
```

This script will:
1. Trigger `RefreshMovie` (metadata update)
2. Trigger `RescanMovie` (disk scan)
3. Wait 3 minutes for operations to complete
4. Display status and results

**When to use:**
- Browser access issues
- Automation/scripting
- Quick terminal access
- After running cleanup scripts

---

## 🔧 **Settings → Media Management Explained**

**This page does NOT have manual refresh buttons!**

Instead, it has **automatic behavior settings**:

### **What You'll See:**

#### **Movie Folders**
- Your root folders (where movies are stored)
- **NOT** where you trigger scans

#### **File Management**
- Rename movies
- Replace illegal characters
- **NOT** where you trigger scans

#### **Permissions**
- Set file permissions
- Change file date
- **NOT** where you trigger scans

#### **Importing**
- Copy/Hardlink behavior
- **NOT** where you trigger scans

#### **Root Folders**
- Add/remove storage locations
- **NOT** where you trigger scans

### **The Confusion:**

Many users expect a "Scan Now" button here because other apps (Plex, Sonarr) have it in their media settings. **Radarr doesn't** - it's in **System → Tasks** instead.

---

## 📋 **Common Refresh Scenarios**

### **Scenario 1: Deleted Corrupted Files (Like Today)**

**What to do:**
1. Delete the files
2. **System → Tasks → Rescan Disk** ▶️
3. Wait 3-5 minutes
4. Check Movies page - missing movies should appear
5. **System → Tasks → Missing Movies Search** ▶️ (if you want auto-search)

**OR Terminal:**
```bash
./scripts/radarr_quick_refresh.sh
```

---

### **Scenario 2: Added New Files Manually**

**What to do:**
1. Copy files to Radarr's root folder
2. **System → Tasks → Rescan Disk** ▶️
3. Wait 2-3 minutes
4. Files should be detected and imported

**OR:**
- **Movies page** → Select movies → **Edit** → **Refresh & Scan**

---

### **Scenario 3: Changed Monitoring Status**

**What to do:**
1. Enable/disable monitoring for movies
2. **System → Tasks → Refresh Movies** ▶️
3. Changes take effect immediately

**Note:** This is what we did today for the 5 Kids Movies!

---

### **Scenario 4: Files Not Showing Up**

**Troubleshooting:**
1. **System → Tasks → Rescan Disk** ▶️
2. Wait 5 minutes
3. Still not there? Check:
   - File naming matches Radarr format: `Movie Title (Year).ext`
   - Files are in a Radarr root folder
   - File permissions are correct
   - Not in a subfolder (unless it's a collection)

---

## ⚙️ **Understanding the Two Types of Refresh**

### **1. Refresh Movies** (Metadata)
- **What it does**: Updates movie info from APIs (TMDb, IMDb)
- **Updates**: Posters, ratings, plot, cast, release dates
- **Does NOT**: Scan disk for files
- **Time**: 1-3 minutes
- **Frequency**: Runs automatically every 24 hours

### **2. Rescan Disk** (File Check)
- **What it does**: Scans your storage for file changes
- **Detects**: New files, deleted files, file moves
- **Does NOT**: Update metadata
- **Time**: 2-5 minutes (depends on library size)
- **Frequency**: Runs automatically every 6 hours

### **Best Practice:**
**Always run BOTH after making file changes:**
```bash
1. Rescan Disk (detect file changes)
2. Refresh Movies (update metadata)
```

---

## 🚀 **Quick Reference Commands**

### **Via Terminal (Fastest)**
```bash
# Quick refresh (both operations)
./scripts/radarr_quick_refresh.sh

# Just check status
sshpass -p "$SSH_PASSWORD" ssh youruser@192.168.1.11 \
    'curl -s -H "X-Api-Key: $(docker exec radarr cat /config/config.xml | grep "<ApiKey>" | sed "s/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/")" \
    "http://localhost:7878/api/v3/system/status"'
```

### **Via Browser (When Working)**
```
System → Tasks → Refresh Movies → ▶️
System → Tasks → Rescan Disk → ▶️
```

### **Via API (Advanced)**
```bash
# Get API key
RADARR_KEY=$(docker exec radarr cat /config/config.xml | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')

# Trigger refresh
curl -X POST -H "X-Api-Key: $RADARR_KEY" \
    "http://192.168.1.11:7878/api/v3/command" \
    -d '{"name": "RefreshMovie"}'

# Trigger rescan
curl -X POST -H "X-Api-Key: $RADARR_KEY" \
    "http://192.168.1.11:7878/api/v3/command" \
    -d '{"name": "RescanMovie"}'
```

---

## ⏱️ **How Long Should It Take?**

### **Refresh Movies**
- Small library (< 100): 30 seconds
- Medium library (100-500): 1-2 minutes
- Large library (500-1000): 2-4 minutes
- Your library (~60 movies): **~1 minute**

### **Rescan Disk**
- Single root folder: 1-2 minutes
- Multiple root folders: 2-4 minutes
- USB drive (slower I/O): 3-5 minutes
- Your setup (USB + NAS): **~3 minutes**

### **Combined (Both Operations)**
- **Total Expected Time**: 3-5 minutes
- **What to do**: Wait! Don't check results immediately
- **When to check**: After 5 minutes, then look at results

---

## 🔍 **How to Monitor Progress**

### **Option 1: System → Tasks**
- Shows all running tasks
- Shows ETA for each task
- Green checkmark = completed
- Red X = failed

### **Option 2: Activity → Queue**
- Shows active downloads
- NOT where you see refresh status
- Check this AFTER refresh completes

### **Option 3: Terminal Status Check**
```bash
# Check if operations are still running
sshpass -p "$SSH_PASSWORD" ssh youruser@192.168.1.11 'bash -s' << 'EOF'
RADARR_KEY=$(docker exec radarr cat /config/config.xml | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
curl -s -H "X-Api-Key: $RADARR_KEY" "http://localhost:7878/api/v3/command" | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
for cmd in data[:5]:
    if 'Refresh' in cmd['name'] or 'Rescan' in cmd['name']:
        print(f\"{cmd['name']}: {cmd['status']}\")
"
EOF
```

---

## ❌ **Common Mistakes**

### **Mistake 1: Looking in Settings → Media Management**
- **Wrong**: There's no refresh button there
- **Correct**: Go to System → Tasks

### **Mistake 2: Checking Results Immediately**
- **Wrong**: Checking 10 seconds after triggering
- **Correct**: Wait 3-5 minutes, THEN check

### **Mistake 3: Not Running Both Operations**
- **Wrong**: Only running Refresh Movies
- **Correct**: Run BOTH Refresh + Rescan after file changes

### **Mistake 4: Running Too Frequently**
- **Wrong**: Running every minute
- **Correct**: Run once, wait for completion, check results

---

## 💡 **Pro Tips**

### **Tip 1: Use Terminal for Speed**
If you're doing multiple operations (delete files, trigger refresh, check status), use the terminal script:
```bash
./scripts/radarr_quick_refresh.sh
```
It's faster than clicking through the UI.

### **Tip 2: Check Command Status First**
Before declaring "it didn't work," check if the command is still running:
- **System → Tasks** → Look for spinning icon
- **OR** use the terminal status check above

### **Tip 3: Enable Monitoring First**
If movies aren't in the queue after refresh:
1. Check if they're **monitored** (Movies page)
2. If not, enable monitoring
3. THEN trigger search

### **Tip 4: Automate After Cleanup Scripts**
Add this to the end of your cleanup scripts:
```bash
# Trigger Radarr refresh after deleting files
RADARR_KEY=$(docker exec radarr cat /config/config.xml | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
curl -X POST -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/command" \
    -d '{"name": "RescanMovie"}'
```

---

## 🎯 **Today's Example**

**What we did:**
1. Deleted 24 corrupted files
2. Ran `delete_corrupted_media.sh` which triggered:
   - `RefreshMovie`
   - `RescanMovie`
3. **Waited 3 minutes**
4. Checked status → Operations completed
5. **Then** enabled monitoring for 5 Kids Movies
6. **Then** triggered searches
7. **Waited 3 more minutes**
8. Checked results → 5 downloads queued ✅

**Key lesson**: Wait for each step to complete before moving to the next!

---

## 📚 **Related Documentation**

- **LESSONS_LEARNED.md** - Operation timing requirements
- **RADARR_MANUAL_FIX_GUIDE.md** - Manual search fallback
- **scripts/radarr_quick_refresh.sh** - Automated refresh script
- **scripts/delete_corrupted_media.sh** - Includes automatic refresh triggers

---

## 🆘 **Still Can't Find It?**

### **If you can access the UI:**
1. **Go to**: http://192.168.1.11:7878
2. **Click**: The **calendar/tasks icon** (⚙️) in the left sidebar
3. **You should see**: "System" → "Tasks" in the navigation
4. **Look for**: A list of scheduled tasks with ▶️ buttons

### **If you can't access the UI:**
Use the terminal script:
```bash
cd ~/Documents/Personal/home_lab
./scripts/radarr_quick_refresh.sh
```

### **If the script doesn't work:**
Check if Radarr is running:
```bash
sshpass -p "$SSH_PASSWORD" ssh youruser@192.168.1.11 \
    'docker ps | grep radarr'
```

---

**Created**: January 3, 2026
**Author**: Based on Radarr v4+ interface
**Last Tested**: January 3, 2026 @ 10:35 AM

