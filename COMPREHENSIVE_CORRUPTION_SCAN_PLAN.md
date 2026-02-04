# Comprehensive Corruption Scan Plan

**Date**: January 3, 2026
**Status**: ✅ **READY TO EXECUTE**

---

## ✅ **DELETIONS COMPLETED**

### **Corrupted Files Deleted (2):**
- ✅ The Wild Robot (2024) - NAS Movies - 5,104 errors
- ✅ Z-O-M-B-I-E-S 3 (2022) - NAS Kids Movies - 5,414 errors

### **Low-Quality Duplicates Deleted (16+):**
- ✅ Black Panther Wakanda Forever (LOW quality)
- ✅ Chicken Run Dawn Of The Nugget (2 copies - LOW quality)
- ✅ Elemental (2 HDTS versions)
- ✅ Mighty Morphin Power Rangers (LOW quality)
- ✅ Puss in Boots (2 copies - LOW quality)
- ✅ The Grinch (LOW quality)
- ✅ The Little Mermaid (TS version)
- ✅ The Mitchells vs The Machines (2 copies - LOW quality)
- ✅ The Wild Robot (2 copies - LOW quality + corrupted)
- ✅ Transformers One (2 copies - LOW quality)
- ✅ **Lightyear (HQCAM version)** - FIXED! ✅

### **Total Files Deleted:**
- **18+ files/directories** (corrupted + low-quality)
- **Storage freed**: Estimated 50-100GB+ (depending on file sizes)

---

## 📋 **COMPREHENSIVE CORRUPTION SCAN PLAN**

### **Paths to Scan:**

#### **NAS Paths:**
1. `/home/youruser/synology/media/Movies` - NAS Movies
2. `/home/youruser/synology/media/TV Shows` - NAS TV Shows
3. `/home/youruser/synology/media/Movies - Kids` - NAS Kids Movies
   - **197 files found** (357GB) - previously unscanned!
4. `/home/youruser/synology/media/TV Shows - Kids` - NAS Kids TV Shows

#### **USB Paths:**
5. `/external/media/Movies` - USB Movies
6. `/external/media/TV` - USB TV Shows
7. `/external/media/Kids Movies` - USB Kids Movies
8. `/external/media/Kids TV Shows` - USB Kids TV Shows

**Total**: 8 media locations

---

## 🔬 **SCAN METHODOLOGY**

### **Enhanced Sampling Strategy:**
- **5 sample points** per file (vs 3 in previous scan):
  - Start (0%)
  - 25% through file
  - Middle (50%)
  - 75% through file
  - End (last 2 minutes)
- **2 minutes per sample** (total 10 minutes of sampling per file)
- **Error detection**: NAL unit errors, corruption, invalid data

### **Classification:**
- **CORRUPT**: >50 errors (must re-download)
- **SUSPICIOUS**: 10-50 errors (test playback, may need re-download)
- **OK**: <10 errors (clean file)

---

## ⏱️ **ESTIMATED SCAN TIME**

### **File Counts (Approximate):**
- NAS Movies: ~787 files
- NAS TV Shows: ~314 files (episodes)
- NAS Kids Movies: **197 files** (previously unscanned!)
- NAS Kids TV Shows: Unknown
- USB Movies: ~139 files
- USB TV Shows: ~99 files
- USB Kids Movies: ~221 files
- USB Kids TV Shows: Unknown

**Total Estimated**: ~1,500-2,000 files

### **Time Estimate:**
- **Per file**: ~2-3 minutes (5 samples × 30 seconds each + overhead)
- **Total time**: ~50-100 hours (2-4 days) if run sequentially
- **Recommended**: Run in background using screen session

---

## 🚀 **EXECUTION OPTIONS**

### **Option 1: Background Screen Session (Recommended)**
```bash
# Upload script
cat scripts/comprehensive_corruption_scan.sh | sshpass -p "$SSH_PASSWORD" ssh youruser@192.168.1.11 'cat > ~/comprehensive_corruption_scan.sh && chmod +x ~/comprehensive_corruption_scan.sh'

# Run in screen
ssh youruser@192.168.1.11
screen -dmS comprehensive_scan ~/comprehensive_corruption_scan.sh

# Check progress
screen -r comprehensive_scan
```

### **Option 2: Parallel Workers (Faster)**
Modify script to use parallel workers (like `parallel_media_scan.sh`):
- 8 parallel workers
- Split files across workers
- Real-time progress display

### **Option 3: Batch Processing (Safest)**
Scan one path at a time:
1. Start with NAS Kids Movies (197 files - previously unscanned)
2. Then NAS Movies
3. Then USB paths
4. Finally TV Shows (largest)

---

## 📊 **EXPECTED RESULTS**

### **Based on Previous Scans:**
- **High Priority Scan**: Found 24 corrupted files (41GB)
- **Duplicate Scan**: Found 2 corrupted files during quality checks
- **Estimated corruption rate**: ~1-2% of files

### **Expected from Comprehensive Scan:**
- **1,500-2,000 files scanned**
- **15-40 corrupted files** (estimated)
- **30-80 suspicious files** (estimated)
- **Total corrupted storage**: ~50-150GB

---

## 📝 **OUTPUT FILES**

Scan will create:
1. `/tmp/comprehensive_scan_results.txt` - All results
2. `/tmp/comprehensive_corrupted_files.txt` - Corrupted files only
3. `/tmp/comprehensive_suspicious_files.txt` - Suspicious files only

---

## 🔄 **POST-SCAN ACTIONS**

1. **Review Results**
   - Check corrupted files list
   - Verify suspicious files
   - Confirm file paths

2. **Delete Corrupted Files**
   - Use deletion script or manual deletion
   - Trigger Radarr/Sonarr refreshes
   - Trigger re-downloads for monitored content

3. **Investigate Suspicious Files**
   - Test playback
   - Re-scan if needed
   - Delete if confirmed corrupted

4. **Update Radarr/Sonarr**
   - Rescan all libraries
   - Trigger missing file searches
   - Verify all tracked content

---

## ⚠️ **CONSIDERATIONS**

### **Storage Space:**
- Low storage may cause corruption
- Current: USB 11% free, NAS 7.3% free
- Monitor during scan

### **Network Performance:**
- Scanning over network (NAS) may be slower
- USB paths will be faster
- Consider time-of-day for network scans

### **System Resources:**
- Docker containers for ffmpeg
- Network I/O for NAS paths
- Disk I/O for USB paths
- May impact other services if run during peak times

---

## ✅ **READY TO EXECUTE**

### **Prerequisites:**
- ✅ Script created: `scripts/comprehensive_corruption_scan.sh`
- ✅ Deletions completed
- ✅ Radarr/Sonarr refreshed
- ✅ Paths verified

### **Next Step:**
Run the comprehensive scan when ready:
```bash
# Quick start
ssh youruser@192.168.1.11
cd ~
bash comprehensive_corruption_scan.sh --background
```

Or run one path at a time:
```bash
# Start with NAS Kids Movies (197 files)
bash comprehensive_corruption_scan.sh
```

---

**Created**: January 3, 2026
**Status**: Ready for execution
**Estimated Duration**: 2-4 days (background) or 1-2 weeks (evening runs)

