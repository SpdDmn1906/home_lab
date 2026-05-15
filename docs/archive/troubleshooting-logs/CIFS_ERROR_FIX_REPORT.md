# CIFS VFS Error Fix Report

**Date**: January 5, 2026
**Server**: mediaserver (192.168.1.11)
**Status**: ⚠️ **Fixes Identified - Manual Execution Required**

---

## 🔍 Errors Identified

### Error 1: Server Inode Numbers Warning
```
CIFS VFS: Autodisabling the use of server inode numbers on \\192.168.1.20\Hulk.
This server doesn't seem to support them properly. Hardlinks will not be recognized
on this mount. Consider mounting with the "noserverino" option to silence this message.
```

**Root Cause**: Synology NAS doesn't properly support server inode numbers, but the mount is trying to use them.

**Fix**: Add `noserverino` option to CIFS mount options.

### Error 2: Close Unmatched Open
```
CIFS VFS: Close unmatched open
```

**Root Cause**: Connection handling issues, often related to network interruptions or improper mount options.

**Fix**: Add `soft` option to prevent hangs, and improve timeout/retry settings.

---

## 📊 Current Configuration

### fstab Entries (Before Fix)
```bash
//192.168.1.20/Hulk /home/youruser/synology cifs \
  credentials=/home/youruser/.smbcredentials,\
  vers=3.0,\
  uid=1000,\
  gid=1004,\
  file_mode=0775,\
  dir_mode=0775,\
  iocharset=utf8,\
  noperm \
  0 0

//192.168.1.20/Hulk/Media /data/media cifs \
  credentials=/home/youruser/.smbcredentials,\
  vers=3.0,\
  uid=1000,\
  gid=1004,\
  file_mode=0775,\
  dir_mode=0775,\
  iocharset=utf8,\
  noperm \
  0 0
```

**Issues**:
- ❌ Missing `noserverino` (causes inode warnings)
- ❌ Missing `soft` (can cause hangs on errors)
- ❌ No explicit timeout/retry settings

### Current Mount Status
```bash
//192.168.1.20/Hulk on /home/youruser/synology type cifs \
  (rw,relatime,vers=3.0,cache=strict,username=SCAdmin,domain=,uid=1000,forceuid,\
   gid=1004,forcegid,addr=192.168.1.20,file_mode=0775,dir_mode=0775,soft,nounix,\
   mapposix,noperm,rsize=1048576,wsize=1048576,echo_interval=60,actimeo=1)

//192.168.1.20/Hulk/Media on /data/media type cifs \
  (rw,relatime,vers=3.0,cache=strict,username=SCAdmin,domain=,uid=1000,forceuid,\
   gid=1004,forcegid,addr=192.168.1.20,file_mode=0775,dir_mode=0775,soft,nounix,\
   mapposix,noperm,rsize=1048576,wsize=1048576,echo_interval=60,actimeo=1)
```

**Note**: Mounts are active but missing `noserverino` option.

---

## ✅ Recommended Fix

### Updated fstab Entries (After Fix)
```bash
# ==============================================================================
# NAS Mounts - CIFS with full user permissions (FIXED)
# ==============================================================================
# User: youruser (uid=1000, gid=1004)
# Permissions: file_mode=0775, dir_mode=0775 (rwxrwxr-x)
# Options:
#   - noserverino: Disable server inode numbers (FIXES CIFS VFS warnings)
#   - noperm: Don't enforce server permissions (use local uid/gid/modes)
#   - iocharset=utf8: Handle international characters
#   - vers=3.0: Use SMB3 protocol
#   - soft: Don't hang on errors (prevents "Close unmatched open" issues)
#   - timeo=600: 10 minute timeout
#   - retrans=3: Retry 3 times
# ==============================================================================

//192.168.1.20/Hulk /home/youruser/synology cifs \
  credentials=/home/youruser/.smbcredentials,\
  vers=3.0,\
  uid=1000,\
  gid=1004,\
  file_mode=0775,\
  dir_mode=0775,\
  iocharset=utf8,\
  noperm,\
  noserverino,\
  soft,\
  timeo=600,\
  retrans=3 \
  0 0

//192.168.1.20/Hulk/Media /data/media cifs \
  credentials=/home/youruser/.smbcredentials,\
  vers=3.0,\
  uid=1000,\
  gid=1004,\
  file_mode=0775,\
  dir_mode=0775,\
  iocharset=utf8,\
  noperm,\
  noserverino,\
  soft,\
  timeo=600,\
  retrans=3 \
  0 0
```

### Key Changes
1. **Added `noserverino`**: Prevents inode number warnings
2. **Added `soft`**: Prevents system hangs on network errors
3. **Added `timeo=600`**: 10-minute timeout for operations
4. **Added `retrans=3`**: Retry failed operations 3 times

---

## 🔧 Implementation Steps

### Option 1: Automated Script (Recommended)

A fix script has been created and uploaded to your server:

```bash
# Connect to server
ssh youruser@192.168.1.11

# Run the fix script
bash ~/fix_cifs_errors_manual.sh
```

The script will:
1. Backup `/etc/fstab`
2. Update fstab entries with `noserverino` and other fixes
3. Stop systemd mount services
4. Unmount existing mounts
5. Reload systemd
6. Remount with new options
7. Verify the changes

### Option 2: Manual Fix

If you prefer to apply the fix manually:

```bash
# 1. Backup fstab
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)

# 2. Edit fstab
sudo nano /etc/fstab

# 3. Update the two CIFS mount lines to include:
#    noserverino,soft,timeo=600,retrans=3

# 4. Stop systemd mount services
sudo systemctl stop data-media.mount
sudo systemctl stop home-youruser-synology.mount

# 5. Unmount
sudo umount -l /data/media
sudo umount -l /home/youruser/synology

# 6. Reload systemd
sudo systemctl daemon-reload

# 7. Remount
sudo mount /home/youruser/synology
sudo mount /data/media

# 8. Verify
mount | grep cifs
```

---

## ✅ Verification

After applying the fix, verify:

```bash
# Check mount options include noserverino
mount | grep cifs | grep noserverino

# Check for CIFS errors (should be none after reboot)
dmesg | grep -i cifs
journalctl -k | grep -i cifs

# Test file operations
touch /home/youruser/synology/.test && rm /home/youruser/synology/.test
touch /data/media/.test && rm /data/media/.test
```

---

## 📋 Expected Results

### Before Fix
- ❌ CIFS VFS inode warnings in kernel log
- ❌ "Close unmatched open" errors
- ⚠️ Potential system hangs on network errors

### After Fix
- ✅ No inode warnings
- ✅ No "Close unmatched open" errors
- ✅ Better error handling with soft mounts
- ✅ Improved timeout/retry behavior

---

## 🔄 Systemd Mount Units

Your mounts are managed by systemd (generated from fstab):
- `data-media.mount`
- `home-youruser-synology.mount`

These units are automatically generated from `/etc/fstab`, so updating fstab and reloading systemd will update the mount options.

---

## 📝 Additional Recommendations

### 1. Monitor CIFS Health
Create a monitoring script to check for CIFS errors:

```bash
#!/bin/bash
# Check for recent CIFS errors
RECENT=$(dmesg | grep -i "cifs\|smb" | tail -5)
if [ -n "$RECENT" ]; then
    echo "⚠️  Recent CIFS messages:"
    echo "$RECENT"
fi
```

### 2. Network Stability
Ensure network stability between server and NAS:
- Check for packet loss: `ping -c 100 192.168.1.20 | grep packet`
- Verify NAS is responsive: `smbclient -L //192.168.1.20 -U SCAdmin`

### 3. Consider SMB 3.1.1
For better performance, consider upgrading to `vers=3.11`:
- Requires Synology NAS to support SMB 3.1.1
- Check NAS SMB settings in Control Panel → File Services → SMB

---

## 🚨 Important Notes

1. **Reboot Recommended**: After applying the fix, a reboot will ensure all mounts use the new options cleanly.

2. **Backup First**: Always backup `/etc/fstab` before making changes.

3. **Test After Fix**: Verify file operations work correctly after applying the fix.

4. **Monitor Logs**: Check kernel logs after reboot to confirm no new errors.

---

## 📚 Related Documentation

- [NETWORK_SERVICE_AND_CIFS_FIXES.md](NETWORK_SERVICE_AND_CIFS_FIXES.md) - Previous CIFS analysis
- [OPTIMIZED_FSTAB_AND_CONFIGURATIONS.md](OPTIMIZED_FSTAB_AND_CONFIGURATIONS.md) - fstab optimization guide

---

**Status**: Ready for implementation
**Priority**: Medium (functional but generating errors)
**Estimated Fix Time**: 5-10 minutes

