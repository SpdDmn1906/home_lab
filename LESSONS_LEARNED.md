# Lessons Learned - Radarr/Sonarr Operations

**Date**: 2026-01-03
**Context**: Media cleanup and re-download automation

---

## ⏱️ **CRITICAL: OPERATION TIMING**

### **Key Learning: Operations Take Time!**

Radarr and Sonarr operations (RefreshMovie, RescanMovie, SeriesSearch, etc.) are **NOT instantaneous**. They run as background jobs that can take **2-5 minutes or more** depending on:

- Library size
- Number of files to scan
- Number of indexers to query
- Network speed to indexers
- Server load

---

## ✅ **CORRECT APPROACH**

### **Step 1: Trigger Operation**
```bash
# Example: Trigger Radarr refresh
curl -X POST -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/command" \
    -d '{"name": "RefreshMovie"}'
```

### **Step 2: WAIT - Don't Check Immediately**
```bash
# Wait at least 2-3 minutes
sleep 180
```

### **Step 3: Check Command Status FIRST**
```bash
# Check if operation is still running
curl -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/command" | \
    grep -o '"name":"RefreshMovie","status":"[^"]*"'
```

**Possible statuses:**
- `"queued"` - Operation waiting to start
- `"started"` - Operation in progress ⏳ **WAIT MORE**
- `"completed"` - Operation finished ✅ **NOW CHECK RESULTS**
- `"failed"` - Operation failed ❌

### **Step 4: Check Results ONLY After Completion**
```bash
# Only check missing count after status is "completed"
curl -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/wanted/missing?pageSize=1"
```

---

## ❌ **INCORRECT APPROACH** (What I Was Doing)

```bash
# Trigger operation
curl -X POST ... -d '{"name": "RefreshMovie"}'

# Check immediately (WRONG!)
sleep 10
curl ... wanted/missing

# Declare failure because results haven't updated yet (WRONG!)
echo "No missing movies found"
```

**Why this fails:**
- Operation is still running in background
- Database hasn't been updated yet
- Results won't reflect changes until operation completes

---

## 📋 **OPERATION TIMINGS**

### **Radarr Operations**

| Operation | Description | Typical Time | Wait Before Checking |
|-----------|-------------|--------------|---------------------|
| `RefreshMovie` | Update metadata from APIs | 1-3 min | 3 minutes |
| `RescanMovie` | Scan disk for files | 2-5 min | 5 minutes |
| `missingMoviesSearch` | Search indexers for missing | 3-10 min | 5 minutes |
| `MoviesSearch` | Search for specific movie | 30 sec - 2 min | 2 minutes |

### **Sonarr Operations**

| Operation | Description | Typical Time | Wait Before Checking |
|-----------|-------------|--------------|---------------------|
| `RefreshSeries` | Update metadata from APIs | 1-3 min | 3 minutes |
| `RescanSeries` | Scan disk for files | 2-5 min | 5 minutes |
| `SeriesSearch` | Search for all missing episodes | 5-15 min | 10 minutes |
| `EpisodeSearch` | Search for specific episode | 30 sec - 2 min | 2 minutes |
| `missingEpisodeSearch` | Search all missing monitored | 10-30 min | 15 minutes |

---

## 🔍 **HOW TO PROPERLY MONITOR**

### **Option 1: Poll Command Status**
```bash
# Poll until operation completes
while true; do
    status=$(curl -s -H "X-Api-Key: $RADARR_KEY" \
        "http://localhost:7878/api/v3/command" | \
        grep -o '"name":"RefreshMovie".*"status":"[^"]*"' | \
        tail -1 | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

    if [ "$status" = "completed" ]; then
        echo "Operation completed!"
        break
    elif [ "$status" = "failed" ]; then
        echo "Operation failed!"
        break
    elif [ "$status" = "started" ] || [ "$status" = "queued" ]; then
        echo "Still running... ($status)"
        sleep 30
    else
        echo "Operation finished or not found"
        break
    fi
done
```

### **Option 2: Fixed Wait Period**
```bash
# Trigger operation
echo "Triggering RefreshMovie..."
curl -X POST ... -d '{"name": "RefreshMovie"}'

# Wait appropriate time
echo "Waiting 3 minutes for operation to complete..."
sleep 180

# Check results
echo "Checking results..."
curl ... wanted/missing
```

### **Option 3: UI Monitoring** (Most Reliable)
- Open Radarr/Sonarr web UI
- Go to: System → Tasks → Queue
- Watch operation progress in real-time
- Check results after queue is empty

---

## ⚠️ **COMMON MISTAKES**

### **Mistake 1: Checking Too Soon**
```bash
# Trigger
curl ... RefreshMovie
# Check 10 seconds later (TOO SOON!)
sleep 10
curl ... wanted/missing
```
**Result**: No changes detected, operation still running in background

### **Mistake 2: Not Checking Command Status**
```bash
# Trigger and wait
curl ... RefreshMovie
sleep 120
# But command might still be running!
curl ... wanted/missing
```
**Result**: Premature results, might miss changes

### **Mistake 3: Assuming Instant Updates**
```bash
# Delete files
rm -rf /path/to/movies
# Check Radarr immediately
curl ... wanted/missing
```
**Result**: Radarr still thinks files exist (cache not updated)

---

## ✅ **BEST PRACTICES**

### **1. Always Trigger, Wait, Verify**
```bash
# 1. Trigger
response=$(curl -X POST ... -d '{"name": "RefreshMovie"}')
command_id=$(echo "$response" | grep -o '"id":[0-9]*' | cut -d: -f2)

# 2. Wait with status monitoring
echo "Waiting for operation to complete..."
for i in {1..10}; do
    sleep 30
    status=$(curl ... command | grep "\"id\":$command_id" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    echo "  Check $i/10: $status"
    [ "$status" = "completed" ] && break
done

# 3. Verify results
if [ "$status" = "completed" ]; then
    curl ... wanted/missing
fi
```

### **2. Use Appropriate Wait Times**

**Quick operations** (< 2 min):
- Single movie search
- Single episode search
- Small library refresh

**Medium operations** (2-5 min):
- Full library refresh
- Disk rescan
- Series search (< 50 episodes)

**Long operations** (5-30 min):
- Missing movies search (100+ movies)
- Missing episodes search (1000+ episodes)
- Large library disk scan

### **3. Check Logs for Errors**

If operation status shows "failed":
```bash
# Check recent logs
docker logs radarr --tail 50
docker logs sonarr --tail 50
```

---

## 📊 **TODAY'S SPECIFIC CASE**

### **What Happened:**

1. **Deleted 24 corrupted files** ✅
2. **Triggered RefreshMovie** ✅
3. **Checked status too soon** ❌ (10-30 seconds)
4. **Saw 0 missing movies** - Operation still running
5. **Waited longer and checked again** ✅
6. **Found 57 missing movies** ✅ - Operation had completed

### **Correct Timeline:**

```
00:00 - Delete files
00:01 - Trigger RefreshMovie
00:01 - Trigger RescanMovie
00:04 - Check command status (still running)
00:06 - Check command status (completed)
00:07 - Check wanted/missing (57 movies found!)
00:08 - Trigger missingMoviesSearch
```

### **What I Did Wrong:**

```
00:00 - Delete files
00:01 - Trigger RefreshMovie
00:01 - Check wanted/missing (too soon!)
00:02 - Report "0 missing movies" (wrong!)
```

---

## 📝 **AUTOMATION SCRIPT TEMPLATE**

Here's the correct way to automate with proper waiting:

```bash
#!/bin/bash

trigger_and_wait() {
    local operation=$1
    local wait_time=$2
    local api_key=$3
    local api_url=$4

    echo "🔄 Triggering: $operation"

    # Trigger operation
    response=$(curl -s -X POST -H "X-Api-Key: $api_key" \
        -H "Content-Type: application/json" \
        "$api_url/api/v3/command" \
        -d "{\"name\": \"$operation\"}")

    command_id=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

    if [ -z "$command_id" ]; then
        echo "   ❌ Failed to trigger operation"
        return 1
    fi

    echo "   ✅ Triggered (ID: $command_id)"
    echo "   ⏱️  Waiting up to $wait_time seconds..."

    # Monitor progress
    for i in $(seq 1 $((wait_time / 30))); do
        sleep 30

        status=$(curl -s -H "X-Api-Key: $api_key" \
            "$api_url/api/v3/command" | \
            grep "\"id\":$command_id" | \
            grep -o '"status":"[^"]*"' | \
            cut -d'"' -f4)

        if [ "$status" = "completed" ]; then
            echo "   ✅ Completed in $((i * 30)) seconds"
            return 0
        elif [ "$status" = "failed" ]; then
            echo "   ❌ Failed"
            return 1
        else
            echo "   ⏳ Still running... ($status)"
        fi
    done

    echo "   ⚠️  Timeout after $wait_time seconds (may still be running)"
    return 2
}

# Usage example
RADARR_KEY="your-api-key"
RADARR_URL="http://localhost:7878"

# Refresh movies and wait up to 5 minutes
trigger_and_wait "RefreshMovie" 300 "$RADARR_KEY" "$RADARR_URL"

# Only check results if operation completed
if [ $? -eq 0 ]; then
    echo "Checking for missing movies..."
    curl -H "X-Api-Key: $RADARR_KEY" \
        "$RADARR_URL/api/v3/wanted/missing?pageSize=10"
fi
```

---

## 🎯 **KEY TAKEAWAYS**

1. ✅ **Always wait 2-5 minutes** after triggering operations
2. ✅ **Check command status** before checking results
3. ✅ **Don't declare failure prematurely** - operations take time
4. ✅ **Use appropriate timeouts** based on operation type
5. ✅ **Monitor via UI** when possible for real-time feedback
6. ✅ **CRITICAL: Check monitoring status FIRST** - searches only run for monitored content

---

## 📚 **UPDATED DOCUMENTATION**

All future automation scripts will follow this pattern:
1. Trigger operation
2. Get command ID
3. Monitor status with polling
4. Wait for "completed" status
5. Only then check results
6. Handle "failed" status appropriately

---

## 🚨 **MONITORING STATUS CHECK**

### **CRITICAL LESSON: Always Check Monitoring BEFORE Triggering Searches**

**Today's Discovery (2026-01-03):**

The `MissingMoviesSearch` command reported:
```
"Completed search for 57 movies. 0 reports downloaded."
```

**What I thought:** Search ran for all 57 movies, found nothing
**Reality:** Only searched the **10 monitored movies**, ignored the other 47

### **The Fix:**

```bash
# 1. FIRST check which missing movies are actually monitored
curl -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/wanted/missing?pageSize=100" | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
monitored = [m for m in data.get('records', []) if m.get('monitored', False)]
print(f'Monitored missing: {len(monitored)} / {data.get(\"totalRecords\", 0)}')
"

# 2. If missing movies aren't monitored, enable monitoring
# (See enable_monitoring_script in repository)

# 3. THEN trigger search for those specific movies
curl -X POST -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/command" \
    -d '{"name": "MoviesSearch", "movieIds": [476, 628, 1142]}'

# 4. Wait 3-5 minutes

# 5. Check queue for downloads
curl -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/queue"
```

### **Key Points:**

- ✅ Radarr only searches for **monitored** content
- ✅ `MissingMoviesSearch` skips unmonitored movies (even if missing)
- ✅ Check monitoring status FIRST before declaring search failure
- ✅ Enable monitoring for content you want to auto-download

### **Quick Check Command:**

```bash
# Count monitored vs unmonitored missing movies
RADARR_KEY="your-api-key"
curl -s -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/wanted/missing?pageSize=1000" | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
total = data.get('totalRecords', 0)
monitored = sum(1 for m in data.get('records', []) if m.get('monitored', False))
print(f'Missing: {total} total, {monitored} monitored, {total-monitored} unmonitored')
if total > monitored:
    print('⚠️  WARNING: Some missing movies are not monitored and will not auto-search')
"
```

---

**Thank you for the feedback! This will make all future automation much more reliable.** 🙏

