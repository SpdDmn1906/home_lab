# Mac Pro External Drive Disconnection Analysis

**Date:** 2026-01-12
**Target:** Janelle's Mac Pro (192.168.1.133)
**Issue:** External drives disconnecting randomly, connected via hub adapter

## System Information

- **Device:** Mac mini (not Mac Pro - hostname: Janelles-Mac-mini.local)
- **macOS Version:** 15.4.1 (Sequoia)
- **Kernel:** Darwin 24.4.0
- **Uptime:** 12+ hours
- **Architecture:** ARM64 (Apple Silicon)

## External Drives Detected

### 1. Silicon-Power 2TB Drive (disk5)
- **Volume:** "JC YT Biz"
- **File System:** HFS+ (Journaled)
- **Capacity:** 2.0 TB
- **Used:** 789.7 GB (39.5%)
- **Free:** 1.2 TB (60.5%)
- **Connection:** USB 3.1 (Up to 5 Gb/s)
- **Location:** Direct connection to USB 3.1 Bus (NOT through hub)
- **Power:** Current Available: 900mA, Current Required: **0mA** ⚠️ (suspicious - should show actual requirement)
- **Status:** Currently mounted and accessible

### 2. Transcend 32GB Drive (disk4)
- **Volume:** "EOS_DIGITAL"
- **File System:** FAT32
- **Capacity:** 32 GB
- **Connection:** USB 2.0 Hub (TERMINUS TECHNOLOGY INC.)
- **Power:** Current Available: 500mA, Current Required: 500mA
- **Status:** Currently mounted and accessible

## USB Hub Configuration

The system has multiple USB hubs in a chain:

1. **Apple Built-in USB3 Gen2 Hub** (10 Gb/s)
   - Contains: VIA Labs USB3.0 Hub
   - Power: 900mA available

2. **Apple Built-in USB2 Hub** (480 Mb/s)
   - Contains: VIA Labs USB2.0 Hub
   - Contains: Dell DA20 Adapter, 2.4G Wireless Receiver
   - Power: 500mA available

3. **TERMINUS TECHNOLOGY USB 2.0 Hub** (480 Mb/s)
   - Contains: Transcend 32GB drive
   - Power: 500mA available, 100mA required for hub

## Key Findings

### ✅ Current Status
- Both external drives are currently mounted and accessible
- No disconnection events found in system logs (last 7 days)
- Disk I/O statistics show normal activity
- S.M.A.R.T. status: Verified (for Silicon-Power drive)

### 🔴 **ROOT CAUSE IDENTIFIED**

**Power Management Setting: `disksleep 10`**

The system is configured to put disks to sleep after **10 minutes of inactivity**. This is the root cause of the issue:

1. **What happens:**
   - External drive "JC YT Biz" sleeps after 10 minutes of inactivity
   - When the computer sleeps and wakes, or when Final Cut Pro resumes, it tries to access the library
   - If the drive hasn't woken up yet, Final Cut Pro cannot access the library location
   - Final Cut Pro has **automatic backup feature** that creates timestamped backup bundles
   - These backups are created in the default location: `~/Movies/Final Cut Backups.localized/`
   - Each backup can be ~10-20MB, and over time they accumulate (currently ~307MB total)
   - Additionally, if Final Cut Pro can't find the original library, it may create a new working library on the local drive

2. **Why it's not logged:**
   - Disk sleep is a normal power management function, not an error
   - The drive doesn't "disconnect" - it just goes to sleep
   - Final Cut Pro doesn't error - it creates backups/new libraries silently
   - Backup creation is expected behavior when the library location is unavailable

3. **Timeline of Backups Found:**
   - Most recent: January 6, 2026 at 12:30 EST
   - Multiple backups from September-October 2025
   - Each timestamped backup indicates when Final Cut Pro couldn't access the external library

4. **Why it happens when computer sleeps/resumes:**
   - Computer sleep triggers drive sleep
   - When computer wakes, drive may take time to wake up
   - Final Cut Pro resumes and tries to access library immediately
   - If drive isn't ready yet, Final Cut Pro creates backup/fallback library

### ⚠️ Additional Issues Identified

1. **Power Reporting Anomaly**
   - Silicon-Power drive shows "Current Required: 0mA" which is incorrect
   - This suggests the drive may not be properly reporting its power requirements
   - Could indicate a driver or hardware communication issue

2. **Hub Chain Complexity**
   - Multiple USB hubs in the chain (Apple built-in → VIA Labs → devices)
   - Each hub adds latency and potential points of failure
   - Power distribution through multiple hubs can cause issues

3. **Drive Connection Location**
   - User mentioned drive is connected via "hub adapter"
   - Diagnostic shows Silicon-Power drive connected directly to USB 3.1 Bus
   - Either the connection changed, or there's a hub that's not being detected properly

## Recommendations

### 🔴 **IMMEDIATE FIX (CRITICAL)**

**Disable Disk Sleep to Prevent Final Cut Pro Library Relocation:**

Run this command on the Mac (requires administrator password):
```bash
sudo pmset -a disksleep 0
```

This will:
- Prevent all disks (including external) from sleeping
- Keep the external drive accessible to Final Cut Pro at all times
- Prevent libraries from relocating to the local drive

**Alternative:** If you want to keep internal drives sleeping but not external:
```bash
sudo pmset -a disksleep 0
# Note: macOS doesn't distinguish between internal/external for disksleep
# So you'll need to disable it for all drives, or use a keep-alive script
```

### Additional System Settings

1. **System Settings → Energy Saver**
   - Uncheck "Put hard disks to sleep when possible" (if available)
   - Set "Prevent computer from sleeping automatically when the display is off" if needed

2. **Final Cut Pro Settings**
   - Final Cut Pro → Preferences → Library Locations
   - Verify the library is set to `/Volumes/JC YT Biz`
   - **Important:** Final Cut Pro → Preferences → General → Library Backup Location
     - Change backup location from default (`~/Movies/Final Cut Backups.localized/`) to external drive
     - Set to: `/Volumes/JC YT Biz/Final Cut Backups/` (create this folder first)
   - Consider creating a symlink if the path keeps changing:
     ```bash
     ln -s "/Volumes/JC YT Biz" ~/Desktop/YT_Biz_Drive
     ```

3. **Clean Up Existing Backups**
   - Current backups on local drive: ~307MB
   - Review and move important backups to external drive:
     ```bash
     mkdir -p "/Volumes/JC YT Biz/Final Cut Backups"
     mv ~/Movies/Final\ Cut\ Backups.localized/* "/Volumes/JC YT Biz/Final Cut Backups/"
     ```
   - Or delete old backups if not needed (keep most recent few)

3. **Check Physical Connection**
   - Verify the actual physical connection path
   - If using a hub adapter, ensure it's a powered hub (with external power supply)
   - Try connecting the Silicon-Power drive directly to a USB port (bypassing any hub)

4. **USB Power Settings**
   - Try different USB ports (especially USB-C/Thunderbolt ports if available)
   - If using a hub, ensure it's externally powered
   - USB 3.1 ports provide more power (900mA) than USB 2.0 (500mA)

### Diagnostic Steps

1. **Monitor for Disconnections**
   ```bash
   # Run this on the Mac to monitor in real-time:
   log stream --predicate 'subsystem == "com.apple.iokit.usb" OR subsystem == "com.apple.diskarbitrationd"' --style compact | grep -iE '(disconnect|remove|eject|error)'
   ```

2. **Check USB Power Consumption**
   - System Information → USB
   - Look for any devices showing power warnings
   - Check if total power draw exceeds port capacity

3. **Test Direct Connection**
   - Disconnect from hub adapter
   - Connect directly to Mac's USB port
   - Monitor for disconnections over 24-48 hours

### Hardware Recommendations

1. **Use Powered USB Hub**
   - If hub adapter is unpowered, replace with externally powered hub
   - Ensures consistent power delivery regardless of Mac's port capacity

2. **Check Cable Quality**
   - Use high-quality USB 3.0+ cables
   - Shorter cables are generally more reliable
   - Avoid cable extenders if possible

3. **Port Selection**
   - Prefer USB-C/Thunderbolt ports (if available) for better power delivery
   - Avoid USB 2.0 ports for high-capacity drives
   - Don't daisy-chain multiple hubs

### Software Recommendations

1. **Update macOS**
   - Current version: 15.4.1
   - Check for updates: System Settings → General → Software Update

2. **Reset USB System** (if issues persist)
   ```bash
   # On the Mac, run:
   sudo kextunload -b com.apple.iokit.IOUSBFamily
   sudo kextload -b com.apple.iokit.IOUSBFamily
   ```
   Note: This requires admin access and may temporarily disconnect USB devices

3. **Check for Third-Party USB Drivers**
   - Some USB hubs require drivers
   - Check manufacturer's website for Mac-compatible drivers

## Scripts Created

### 1. Diagnostic Script
`scripts/diagnose_mac_external_drives.sh`

Run it periodically to check for issues:
```bash
./scripts/diagnose_mac_external_drives.sh 192.168.1.133 janellechung jchung8
```

### 2. Fix Script
`scripts/fix_mac_drive_sleep_issue.sh`

Provides instructions and can help apply the fix:
```bash
./scripts/fix_mac_drive_sleep_issue.sh 192.168.1.133 janellechung jchung8
```

### 3. Keep-Alive Script (Optional)

If you want to keep the drive awake without disabling sleep system-wide, create this script on the Mac:

```bash
#!/bin/bash
# Keep external drive awake by touching a file every 5 minutes
while true; do
    if [ -d "/Volumes/JC YT Biz" ]; then
        touch "/Volumes/JC YT Biz/.keepalive" 2>/dev/null
    fi
    sleep 300  # 5 minutes
done
```

Save as `~/keep_drive_awake.sh`, make executable, and run in background:
```bash
chmod +x ~/keep_drive_awake.sh
nohup ~/keep_drive_awake.sh &
```

## Next Steps

1. **If disconnections continue:**
   - Run the monitoring command above to capture events in real-time
   - Try connecting drive directly (bypass hub)
   - Test with a different USB cable
   - Check if issue occurs with specific applications or during specific activities

2. **If issue is resolved:**
   - Document what fixed it (direct connection, powered hub, etc.)
   - Continue monitoring for a few days to ensure stability

## Log Files

Full diagnostic logs saved to:
- `/Users/StephenChung/mac_drive_diagnostics/diagnostic_2026-01-12_15-17-03.log`

## Additional Notes

- The system shows it's a Mac mini, not a Mac Pro (hostname: Janelles-Mac-mini.local)
- Both drives are currently healthy and accessible
- No immediate errors or warnings in system logs
- The power reporting anomaly (0mA required) is worth investigating further

## Understanding Final Cut Pro's Backup Behavior

### Automatic Backups
Final Cut Pro automatically creates backups when:
- Library is saved
- Library location becomes unavailable
- System resumes from sleep and library can't be found

### Current Backup Situation
- **Location:** `~/Movies/Final Cut Backups.localized/`
- **Size:** ~307MB total (244MB for "JC YT vids" alone)
- **Contents:** Timestamped .fcpbundle files
- **Most Recent:** January 6, 2026 at 12:30 EST
- **Pattern:** Multiple backups created when external drive was unavailable

### Why Backups Appear on Local Drive
When Final Cut Pro cannot access the library on the external drive (because it slept), it creates backups in the default location (`~/Movies/`) rather than on the external drive. This is why the local drive fills up.

### Solution
1. **Disable disk sleep** (primary fix)
2. **Change Final Cut Pro backup location** to external drive (secondary fix)
3. **Clean up existing backups** from local drive (reclaim space)

