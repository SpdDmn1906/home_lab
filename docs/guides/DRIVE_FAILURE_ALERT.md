# 🚨 CRITICAL: S.M.A.R.T. Drive Failure Alert

**Date**: January 7, 2026
**Server**: mediaserver (192.168.1.11)
**Status**: ⚠️ **CRITICAL HARDWARE FAILURE**

---

## 🚨 Drive Failure Details

### Failing Drive
- **Model**: ST32000641AS (Seagate 2TB)
- **Device**: `/dev/sda`
- **Port**: Port 1
- **Status**: S.M.A.R.T. Status Bad
- **Action Required**: **BACKUP AND REPLACE IMMEDIATELY**

### System Impact
- ✅ **Good News**: Drive is NOT currently mounted or in use
- ⚠️ **Boot Issue**: BIOS blocks boot with error screen
- ⚠️ **Error Message**: "Port 1 : ST32000641AS S.M.A.R.T. Status Bad, Backup and Replace"
- ⚠️ **Workaround**: Press F1 in BIOS to continue boot
- ⚠️ **Motherboard Code**: A2 (shown on device display)

---

## 📊 Drive Information

### Partition Layout
```
/dev/sda (1.8TB ST32000641AS)
├─ sda1   1TB   NTFS
├─ sda2   195.3GB
├─ sda3   122.1GB  NTFS
└─ sda4   122.1GB  NTFS
```

### Current Status
- ❌ **Not Mounted**: No partitions are currently mounted
- ❌ **Not in fstab**: No automatic mount configuration
- ⚠️ **S.M.A.R.T. Failure**: Drive has reported critical errors
- ⚠️ **Boot Blocking**: BIOS prevents boot until acknowledged

---

## 🎯 Immediate Actions Required

### Priority 1: Data Assessment (URGENT)
1. **Check if drive contains important data**
   ```bash
   # If drive is accessible, check partitions
   sudo fdisk -l /dev/sda

   # Attempt to mount read-only to check contents (RISKY)
   sudo mount -o ro /dev/sda1 /mnt/temp
   ls -la /mnt/temp | head -20
   sudo umount /mnt/temp
   ```

2. **If data is important**: Backup immediately
   ```bash
   # Create backup (if drive is still readable)
   sudo ddrescue -v /dev/sda /path/to/backup/sda_backup.img /path/to/backup/sda_recovery.log
   ```

### Priority 2: Fix Boot Issue (IMMEDIATE)
**Option A: Disable S.M.A.R.T. Check in BIOS (Recommended)**
1. Boot into BIOS (usually Del, F2, or F12 during boot)
2. Navigate to: **Advanced → Drive Configuration → S.M.A.R.T.**
3. Change **"Halt on S.M.A.R.T. Error"** to **"Disabled"** or **"Log Only"**
4. Save and exit

**Option B: Physically Disconnect Drive (Safest)**
1. Power down server
2. Disconnect SATA cable from failing drive (Port 1)
3. Boot normally (no error screen)
4. Leave drive disconnected until replacement

**Option C: Disable Drive in BIOS**
1. Boot into BIOS
2. Navigate to: **Advanced → Drive Configuration**
3. Set Port 1 to **"Disabled"** or **"Not Installed"**
4. Save and exit

### Priority 3: Drive Replacement
- **If drive has data**: Replace with same or larger capacity drive
- **If drive is unused**: Simply remove it (no replacement needed)
- **Recommended**: Use a new drive with warranty (Seagate Barracuda, WD Blue, etc.)

---

## 🔍 S.M.A.R.T. Status Check

### Install S.M.A.R.T. Tools (if not installed)
```bash
sudo apt update
sudo apt install smartmontools
```

### Check Detailed S.M.A.R.T. Status
```bash
# Overall health
sudo smartctl -H /dev/sda

# Detailed attributes
sudo smartctl -A /dev/sda

# Self-test
sudo smartctl -t short /dev/sda  # Short test
sudo smartctl -t long /dev/sda   # Long test (takes hours)

# View test results
sudo smartctl -l selftest /dev/sda
```

---

## 📋 Current System Storage Status

### Active Drives
- ✅ **/dev/sdb** (Samsung SSD 850, 232.9GB) - System drive (mounted as `/`)
- ✅ **/dev/sdc** (Expansion Desk, 3.7TB) - External media (mounted as `/external/media`)
- ⚠️ **/dev/sda** (ST32000641AS, 1.8TB) - **FAILING - NOT IN USE**

### Mount Points
- `/` → `/dev/sdb2` (SSD, 228GB used, 36GB free)
- `/external/media` → `/dev/sdc2` (External, 2.2TB, 1.5TB used, 645GB free)
- NAS → CIFS mounts (`/data/media`, `/home/youruser/synology`)

---

## ⚠️ Why This Matters

### S.M.A.R.T. Failure Means
- **Iminent Failure**: Drive is reporting critical errors
- **Data Loss Risk**: Drive could fail completely at any time
- **Unreliable**: Drive should not be trusted for any data storage

### If Drive Has Data
- ⚠️ **Backup Immediately**: Drive could fail completely within days/hours
- ⚠️ **Do Not Write**: Writing data could accelerate failure
- ⚠️ **Use Read-Only**: If accessing, mount read-only only

### Boot Issue Impact
- ⚠️ **Annoying**: Must press F1 every boot
- ⚠️ **Remote Boot Problem**: Can't boot unattended
- ⚠️ **Automation Issues**: Scripts/automation may fail on boot

---

## 🛠️ Permanent Solutions

### 1. Replace Drive (If It Has Data)
- Purchase replacement drive (same or larger)
- Copy data from old drive (if accessible)
- Remove old drive from system

### 2. Remove Drive (If Unused)
- Physically disconnect drive
- Remove from system
- Update BIOS configuration

### 3. Configure BIOS Properly
- Disable "Halt on S.M.A.R.T. Error"
- Enable S.M.A.R.T. monitoring only (log, don't halt)
- Set up email alerts if supported

### 4. Set Up S.M.A.R.T. Monitoring
```bash
# Install smartmontools
sudo apt install smartmontools

# Configure daily short tests
sudo systemctl enable smartd
sudo systemctl start smartd

# Edit config
sudo nano /etc/smartd.conf
```

---

## 📝 Recommendations

### Immediate (Today)
1. ✅ **Verify drive contents** - Check if any data needs backup
2. ✅ **Fix boot issue** - Disable S.M.A.R.T. halt in BIOS OR disconnect drive
3. ✅ **Backup data** - If drive has data, backup immediately

### Short Term (This Week)
1. Replace or remove failing drive
2. Set up S.M.A.R.T. monitoring for all drives
3. Document drive inventory and health status

### Long Term (This Month)
1. Set up automated S.M.A.R.T. monitoring
2. Configure alerts for drive failures
3. Create drive replacement plan

---

## 🔗 Related Issues

This is separate from the CIFS mount issues we were fixing, but equally important:
- CIFS errors: Network mount configuration issues
- Drive failure: Hardware failure requiring immediate attention

---

**Status**: ⚠️ **CRITICAL - Action Required**
**Priority**: **HIGH** (affects boot process)
**Data Risk**: **HIGH** (if drive contains data)

