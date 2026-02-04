# Comprehensive Corruption Scan - IN PROGRESS

**Started**: January 4, 2026 @ 2:31 AM EST
**Expected Completion**: 5:31-8:31 AM EST (3-6 hours)
**Status**: ✅ **RUNNING IN BACKGROUND**

---

## 📊 **SCAN CONFIGURATION**

### **Files Being Scanned:**
- **Total**: 3,937 files
  - NAS Movies: 810 files
  - NAS Kids Movies: 187 files
  - NAS TV Shows: 1,471 files
  - USB Movies: 139 files
  - USB Kids Movies: 220 files
  - USB TV Shows: 1,110 files

### **Scan Method:**
- **Full file pass-through** (not sampling)
- **Detects**: Corruption, keyframe issues, freezing problems
- **Workers**: 8 parallel
- **Speed**: ~30 seconds per file with 8 workers

### **Detection Categories:**
1. **CORRUPT**: >50 errors or >20 keyframe issues → Delete immediately
2. **SUSPICIOUS**: 10-50 errors or 5-20 keyframe issues → Test & review
3. **FREEZING_RISK**: 1-5 keyframe issues → Test playback, likely re-download
4. **OK**: Clean files

---

## 📋 **HOW TO MONITOR**

### **Attach to Live Scan:**
```bash
ssh youruser@192.168.1.11
screen -r comprehensive_scan
```

**Inside the screen session:**
- Watch real-time progress bar
- See live worker status
- View corruption counts updating
- See ETA countdown

**To detach (keep scan running):**
- Press: `Ctrl+A` then `D`

### **Check if Scan is Still Running:**
```bash
ssh youruser@192.168.1.11
screen -ls
# Should show: comprehensive_scan
```

### **Quick Progress Check:**
```bash
ssh youruser@192.168.1.11
ps aux | grep ffmpeg | wc -l
# Should show ~8 (one per worker)
```

---

## 📁 **OUTPUT FILES**

When the scan completes, results will be saved to:

1. **`/tmp/comprehensive_scan_results.txt`**
   - Complete results for all 3,937 files
   - Format: `STATUS|errors|keyframes|label|path|file|size`

2. **`/tmp/comprehensive_corrupted_files.txt`**
   - Files with >50 errors or >20 keyframe issues
   - Must be deleted and re-downloaded

3. **`/tmp/comprehensive_suspicious_files.txt`**
   - Files with 10-50 errors or 5-20 keyframe issues
   - Should be tested or reviewed

4. **`/tmp/comprehensive_freezing_files.txt`** ⭐ **NEW**
   - Files with keyframe issues (like Lightyear)
   - May freeze during playback
   - Should test or re-download

---

## ⏰ **ESTIMATED TIMELINE**

### **Best Case:**
- 3,937 files × 25 seconds ÷ 8 workers = **3.2 hours**
- Completion: ~5:45 AM EST

### **Typical Case:**
- 3,937 files × 30 seconds ÷ 8 workers = **4.1 hours**
- Completion: ~6:45 AM EST

### **Worst Case:**
- 3,937 files × 40 seconds ÷ 8 workers = **5.5 hours**
- Completion: ~8:00 AM EST

**Progress indicators:**
- After 1 hour: ~750-1,000 files scanned (19-25%)
- After 2 hours: ~1,500-2,000 files scanned (38-51%)
- After 3 hours: ~2,250-3,000 files scanned (57-76%)
- After 4 hours: ~3,000-3,900 files scanned (76-99%)

---

## 🎯 **WHAT THE SCAN WILL CATCH**

### **Corruption Types:**
1. **NAL unit errors** - Video encoding issues
2. **Decode errors** - Can't decode frames
3. **Corruption** - File damage
4. **Truncation** - Incomplete files
5. **Keyframe issues** ⭐ **Causes freezing** (like Lightyear)
6. **Seek errors** - Can't navigate in file

### **Why Full Pass-Through Matters:**
```
Sampling (Old Method):
File: |====|====|====|====|====|
       ^    ^    ^    ^    ^
      0%  25%  50%  75% EOF
Only tests 10 min of 90 min movie ❌

Full Pass-Through (New Method):
File: |====================|
      ^^^^^^^^^^^^^^^^^^^^^
Tests entire file ✅
```

---

## 📊 **EXPECTED RESULTS**

### **Based on Previous Scans:**
- High-priority scan: 24 corrupted out of ~500 files (4.8%)
- Duplicate scan: 2 corrupted out of ~200 checked (1%)
- **Estimated for this scan**: 40-80 corrupted files (1-2%)
- **Freezing risk files**: 10-30 files (0.3-0.8%)

### **Storage Impact:**
- If 60 files corrupted at 2GB each: ~120GB to free
- If re-downloaded with better quality: Similar size
- Net storage change: ~0GB (delete + re-download)

---

## ✅ **POST-SCAN ACTIONS**

### **Step 1: Review Results**
```bash
ssh youruser@192.168.1.11

# Count results
wc -l /tmp/comprehensive_corrupted_files.txt
wc -l /tmp/comprehensive_freezing_files.txt
wc -l /tmp/comprehensive_suspicious_files.txt

# View corrupted files
cat /tmp/comprehensive_corrupted_files.txt

# View freezing risk files
cat /tmp/comprehensive_freezing_files.txt
```

### **Step 2: Create Deletion Script**
Based on results, I'll create a script to:
- Delete all corrupted files
- Delete all freezing risk files
- Trigger Radarr/Sonarr refreshes
- Trigger searches for missing content

### **Step 3: Execute Cleanup**
- Run deletion script
- Monitor Radarr/Sonarr for re-downloads
- Verify storage freed

### **Step 4: Verify**
- Check Radarr missing count
- Verify re-downloads starting
- Monitor storage levels

---

## 🔍 **TROUBLESHOOTING**

### **If Scan Stops:**
```bash
# Check if screen session exists
screen -ls

# If session exists but seems frozen
screen -r comprehensive_scan
# Check output, Ctrl+C to stop, restart if needed

# Restart scan
bash ~/comprehensive_corruption_scan_parallel.sh --background
```

### **If System is Slow:**
The scan uses:
- 8 ffmpeg Docker containers (CPU intensive)
- Network I/O for NAS files
- Disk I/O for USB files

This is normal and expected.

### **If Storage Fills Up:**
Monitor storage during scan:
```bash
watch -n 60 'df -h /external/media; df -h /home/youruser/synology/media'
```

If storage drops below 5%, the scan may fail.

---

## 📝 **NOTES**

### **Why This Scan is Different:**
1. **Catches Lightyear-type issues** - Full file pass-through finds keyframe problems
2. **Much faster** - 8 parallel workers (hours vs days)
3. **Comprehensive** - All 8 media locations
4. **Three categories** - Corrupt, suspicious, and freezing risk

### **What We Learned from Lightyear:**
- Both files had keyframe issues
- Sampling missed the problems
- Only full pass-through detects freezing
- This scan will catch all such issues

---

## 🎯 **CURRENT STATUS**

- ✅ Scan started: 2:31 AM EST
- ✅ Screen session: Running
- ✅ Workers: 8 parallel active
- ⏳ Progress: Collecting files (0%)
- ⏳ ETA: Calculating...
- ⏳ Corrupted found: 0 (so far)
- ⏳ Freezing risk found: 0 (so far)

---

**Check back in 1 hour for first progress update!**

**Session**: `comprehensive_scan`
**Command**: `screen -r comprehensive_scan`
**Last Updated**: January 4, 2026 @ 2:35 AM
