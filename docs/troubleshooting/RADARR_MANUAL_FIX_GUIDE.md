# Radarr Manual Fix Guide - Force Detection of Deleted Files

**Issue**: Radarr shows deleted movies as still having files
**Cause**: Radarr cache hasn't updated to reflect disk deletions
**Solution**: Manual refresh and search

---

## 🎯 **STEP-BY-STEP FIX**

### **Step 1: Access Radarr**
Open: `http://192.168.1.11:7878`

**If browser won't connect:**
```bash
# From Terminal, open in default browser:
open http://192.168.1.11:7878

# Or try Safari specifically:
open -a Safari http://192.168.1.11:7878
```

---

### **Step 2: Check Individual Deleted Movies**

Go to **Movies** tab and search for each deleted movie:

**Quick check for popular titles:**
1. Search: "Lion King 2019"
2. Search: "Wicked 2024"
3. Search: "Barbie 2023"
4. Search: "Tangled"
5. Search: "Puss in Boots"

**For each movie:**
- Click on the movie
- Look at **File** section
- Does it show a file path?
- Is the file actually there? (We deleted it!)

---

### **Step 3: Force Individual Movie Refresh**

For EACH deleted movie you find:

1. **Click the movie** to open details
2. Click the **Refresh** button (circular arrow icon)
3. Wait 10 seconds
4. Check if **File** section now shows "No file"
5. Check if **Monitored** is enabled (toggle switch should be ON)

**If movie still shows file exists:**
1. Click **Edit** (pencil icon)
2. Note the **Path** shown
3. Check if path matches where we deleted: `/data/media/Kids Movies`
4. If different path, that's the problem!

---

### **Step 4: Check Root Folders**

1. Go to **Settings** → **Media Management**
2. Click **Root Folders**
3. Look for Kids Movies folder path
4. Should be: `/data/media/Kids Movies`

**If path is different**, that explains why Radarr doesn't see deletions!

---

### **Step 5: Manual Search for Missing Movies**

Once movies show as "No file":

**Option A: Search Individual Movie**
1. Click on a missing movie
2. Click **Search** button (magnifying glass icon)
3. Wait for search results
4. Select a release
5. Click **Download**

**Option B: Bulk Search**
1. Go to **Wanted** → **Missing**
2. You should see the 22 deleted movies
3. Check boxes for movies you want
4. Click **Search** (top right)
5. Radarr will search all selected movies

**Option C: Automatic Search All**
1. Go to **Wanted** → **Missing**
2. Click **Search All** button
3. This searches ALL missing monitored movies
4. Downloads will queue automatically

---

## 🔧 **TROUBLESHOOTING**

### **Problem: Movies Don't Show in "Wanted → Missing"**

**Check:**
1. Are movies **Monitored**? (Edit movie → toggle should be ON)
2. Are movies in correct **Root Folder**?
3. Click **Refresh** on each movie individually

### **Problem: Searches Find Nothing**

**Check:**
1. **Settings** → **Indexers** - Are indexers enabled?
2. **Settings** → **Indexers** - Click "Test All"
3. Check **System** → **Logs** for indexer errors
4. Verify Prowlarr is running and synced

### **Problem: Downloads Don't Start**

**Check:**
1. **Settings** → **Download Clients** - Is qBittorrent configured?
2. **Settings** → **Download Clients** - Click "Test"
3. Check if qBittorrent is running: `http://192.168.1.11:8080`
4. Check **Activity** → **Queue** for stuck downloads

---

## 📊 **VERIFICATION SCRIPT**

Run this from your laptop to check status:

```bash
sshpass -p "$SSH_PASSWORD" ssh youruser@192.168.1.11 'bash -s' << 'EOF'
RADARR_KEY=$(docker exec radarr cat /config/config.xml | grep "<ApiKey>" | sed "s/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/")

echo "📊 Radarr Status:"
echo ""

# Check specific deleted movies
for movie in "Lion King" "Wicked" "Barbie" "Tangled" "Puss in Boots"; do
    result=$(curl -s -H "X-Api-Key: $RADARR_KEY" "http://localhost:7878/api/v3/movie" | grep -i "$movie" | grep -o '"hasFile":[^,]*,"monitored":[^,]*' | head -1)
    if [ -n "$result" ]; then
        echo "• $movie: $result"
    fi
done

echo ""
echo "Missing Count: $(curl -s -H "X-Api-Key: $RADARR_KEY" "http://localhost:7878/api/v3/wanted/missing?pageSize=1" | grep -o '"totalRecords":[0-9]*' | cut -d: -f2)"
echo "Queue Count: $(curl -s -H "X-Api-Key: $RADARR_KEY" "http://localhost:7878/api/v3/queue" | grep -c '"title":')"
EOF
```

---

## 🎯 **EXPECTED OUTCOME**

After completing these steps:

✅ **Radarr shows movies as "Missing"** (File: No file)
✅ **Movies appear in Wanted → Missing**
✅ **Searches triggered** (Activity → Queue shows items)
✅ **Downloads start** (qBittorrent shows torrents)
✅ **Files download** to `/data/media/Kids Movies`
✅ **Radarr auto-imports** when complete

---

## 🚨 **IF NOTHING WORKS**

### **Nuclear Option: Manually Remove from Radarr**

If movies still show files that don't exist:

1. Click movie
2. Click **Edit**
3. Scroll to bottom
4. Click **Delete** (trash icon)
5. Check "Delete files" if prompted (even though files are gone)
6. Confirm deletion
7. **Re-add movie:**
   - Click "Add Movies"
   - Search for movie
   - Set path, quality, monitor
   - Enable "Search on add"
   - Click "Add"

This forces a clean slate.

---

## 📝 **DELETED KIDS MOVIES LIST**

Movies to check/fix in Radarr:

1. The Lion King (2019)
2. Wicked (2024)
3. Barbie (2023)
4. Tangled (2010)
5. Puss in Boots: The Last Wish (2022)
6. How to Train Your Dragon (2025)
7. Alice in Wonderland (2010)
8. Harry Potter and the Prisoner of Azkaban (2004)
9. Cars 2 (2011)
10. Tarzan (1999)
11. Open Season (2006)
12. Ratatouille (2007)
13. Snow White and the Seven Dwarfs (1938)
14. Trolls (2016)
15. Trolls World Tour (2020)
16. How to Train Your Dragon 2 (2014)
17. Flushed Away (2006)
18. Rango (2011)
19. Mulan II (2004)
20. Hercules (1997)
21. Miraculous World Paris (2023)
22. Alexander and the Terrible... (2025)

---

**Once you can access Radarr in browser, work through Step 2-5 to get searches running!**

