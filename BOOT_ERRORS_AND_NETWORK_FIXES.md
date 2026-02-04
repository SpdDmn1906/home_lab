# Boot Errors & Network Service Fixes

**Date**: 2025-12-29
**Server**: mediaserver (192.168.1.11)
**Status**: ⚠️ **BOOT ERRORS AND NETWORK SERVICE CONFLICTS FOUND**

---

## 🔴 Critical Boot Errors Found

### 1. systemd-networkd-wait-online.service FAILED

**Error:**
```
● systemd-networkd-wait-online.service - Wait for Network to be Configured
   Active: failed (Result: exit-code) since Sun 2025-12-28 01:32:35 EST
   Event loop failed: Connection timed out
```

**Cause**: Service times out waiting for network configuration (2 minutes timeout)

**Impact**:
- Delays boot process
- Indicates network configuration issues
- Service conflict (NetworkManager and systemd-networkd both enabled)

**Fix**: Disable conflicting services (see Network Services section below)

---

### 2. networking.service Warnings

**Error:**
```
warning: couldn't open interfaces file "/etc/network/interfaces"
```

**Cause**: Missing `/etc/network/interfaces` file (removed or never created)

**Impact**:
- Warnings at boot (not critical)
- Service still starts but can't read configuration

**Fix**: Create minimal interfaces file or disable if using NetworkManager

---

### 3. Intel i915 Graphics Driver Warning

**Error:**
```
WARNING: CPU: 0 PID: 175 at /build/linux-5WyMwj/linux-4.15.0/drivers/gpu/drm/i915/intel_display.c:14537
Could not determine valid watermarks for inherited state
```

**Cause**: Intel integrated graphics driver initialization issue (i915)

**Impact**:
- Boot warning (non-critical)
- May affect hardware video acceleration if using GPU transcoding
- Common with older kernels and newer hardware

**Fix**: Usually harmless, but may need kernel update or driver update

---

### 4. USB Network Adapter Errors (ax88179_178a)

**Error:**
```
ax88179_178a 4-3.2:2.0 (unnamed net_device) (uninitialized): Failed to write reg index 0x0002: -32
ax88179_178a 4-3.2:2.0 (unnamed net_device) (uninitialized): Failed to read reg index 0x0006: -32
```

**Cause**: USB Ethernet adapter (ASIX AX88179) failing to initialize

**Impact**:
- USB network adapter may not work
- Errors during boot
- If you're using this adapter, it's not functional

**Fix**:
- Check if USB adapter is still needed
- Remove/replace adapter if unused
- Try different USB port or cable

---

### 5. ACPI Warnings (Hardware Compatibility)

**Error:**
```
ACPI Warning: SystemIO range conflicts with OpRegion
```

**Cause**: ACPI BIOS issues with older motherboard (ASUS Z87-EXPERT)

**Impact**:
- Boot warnings (usually harmless)
- May cause minor hardware detection issues

**Fix**: Usually safe to ignore, but can suppress with kernel parameters

---

## ✅ Network Service Analysis

**Current Status**: NetworkManager is correctly managing your network.

**Finding**: Despite multiple services enabled, NetworkManager is the active network manager. Your main interface `enxc8a362337330` (192.168.1.11) is managed by NetworkManager and working correctly.

## 🔴 Network Service Conflicts

### Problem: Multiple Network Services Enabled (Some Unnecessary)

**Currently Enabled:**
- ✅ `network-manager.service` (NetworkManager)
- ✅ `networking.service` (ifupdown)
- ✅ `systemd-networkd.service` (systemd-networkd)
- ✅ `systemd-networkd-wait-online.service` (fails at boot)
- ✅ `NetworkManager-wait-online.service`

**Issue**: NetworkManager and systemd-networkd should NOT both be enabled - they conflict!

**Current Status:**
- NetworkManager is managing your network (working)
- systemd-networkd is also enabled but not actively managing (causing conflicts)
- networking.service (ifupdown) is enabled but `/etc/network/interfaces` is missing

---

## ✅ Fixes Required

### Fix #1: Disable Conflicting Network Services

**Problem**: Multiple network management services enabled causing conflicts and boot failures.

**Solution**: Disable unused services (keep only NetworkManager).

```bash
# SSH into server
ssh youruser@192.168.1.11

# Disable systemd-networkd (not needed if using NetworkManager)
sudo systemctl disable systemd-networkd.service
sudo systemctl disable systemd-networkd.socket
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl stop systemd-networkd.service
sudo systemctl stop systemd-networkd.socket
sudo systemctl stop systemd-networkd-wait-online.service

# Option 1: Keep networking.service (ifupdown) but create missing config
# Create minimal /etc/network/interfaces
sudo tee /etc/network/interfaces > /dev/null <<EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback
EOF

# Option 2: OR disable networking.service if not needed
# (Since NetworkManager is handling network, this is likely not needed)
sudo systemctl disable networking.service

# Verify NetworkManager is managing network
ip addr show
# Should show your network interfaces

# Reboot to test
sudo reboot
```

**After Reboot, Verify:**
```bash
# Check failed services
systemctl --failed
# Should NOT show systemd-networkd-wait-online.service

# Check network services
systemctl status NetworkManager
systemctl status networking
# Should show both running or networking disabled

# Check network connectivity
ping -c 3 8.8.8.8
```

---

### Fix #2: Suppress Boot Warnings (Optional)

**For ACPI Warnings:**
```bash
# Edit GRUB configuration
sudo nano /etc/default/grub

# Add to GRUB_CMDLINE_LINUX_DEFAULT:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi=noirq"

# Update GRUB
sudo update-grub

# Reboot
sudo reboot
```

**For Intel Graphics Warnings:**
- Usually safe to ignore
- If using GPU transcoding in Plex, monitor for issues
- May need kernel update for full fix

---

### Fix #3: Fix USB Network Adapter (If Needed)

**If you're NOT using the USB Ethernet adapter:**

```bash
# Blacklist the driver to suppress errors
echo "blacklist ax88179_178a" | sudo tee /etc/modprobe.d/blacklist-ax88179.conf

# Rebuild initramfs
sudo update-initramfs -u

# Reboot
sudo reboot
```

**If you ARE using the USB Ethernet adapter:**

```bash
# Check if adapter is physically connected
lsusb | grep -i ax88179

# Check dmesg for connection issues
dmesg | grep -i ax88179 | tail -20

# Try different USB port
# Check cable
# May need driver update or different adapter
```

---

## 📋 Current Network Service Status

### Enabled Services at Boot

| Service | Status | Action Needed |
|---------|--------|---------------|
| NetworkManager | ✅ Enabled | Keep - Primary network manager |
| networking (ifupdown) | ⚠️ Enabled (no config) | Disable or create config |
| systemd-networkd | ⚠️ Enabled (conflict) | **DISABLE** |
| systemd-networkd-wait-online | ❌ Enabled (fails) | **DISABLE** |
| NetworkManager-wait-online | ✅ Enabled | Keep - Works correctly |

### Recommended Configuration

**Keep Enabled:**
- ✅ `NetworkManager.service`
- ✅ `NetworkManager-wait-online.service`

**Disable:**
- ❌ `systemd-networkd.service`
- ❌ `systemd-networkd.socket`
- ❌ `systemd-networkd-wait-online.service`
- ❌ `networking.service` (if not using ifupdown config)

---

## 🔍 Additional Findings

### No Network Cron Jobs Found ✅

**Good News**: No network-related cron jobs found that run at boot or scheduled times.

**Found Cron Jobs:**
- `/etc/cron.daily/plexupdate` - Updates Plex (legitimate, runs daily)
- Standard system cron jobs (apt, logrotate, etc.) - All normal

**Action**: None needed - no unwanted network cron jobs.

---

## 🐛 Application Errors (Related to Root Access Issue)

### Radarr: Missing ffprobe

**Error:**
```
[Error] DetectSample: Failed to get runtime from the file, make sure ffprobe is available
```

**Cause**: Radarr container missing ffprobe binary for video analysis

**Impact**: Cannot analyze video files for metadata (runtime, resolution, etc.)

**Fix**: This will be resolved when fixing root access (Fix #1 in IMMEDIATE_ACTION_PLAN.md)
- After changing to non-root user, may need to install ffprobe in container
- Or use container with ffprobe included

**Temporary Check:**
```bash
# Check if ffprobe exists in container
docker exec radarr which ffprobe
# Should show path or "not found"

# Check container image
docker inspect radarr --format '{{.Config.Image}}'
# Should be linuxserver/radarr which should include ffprobe
```

---

## 📊 Boot Error Summary

### Critical (Fix Immediately)

1. 🔴 **systemd-networkd-wait-online.service failed** - Causing boot delays
2. 🔴 **Network service conflicts** - Multiple services enabled

### Warnings (Fix Soon)

3. 🟡 **networking.service warnings** - Missing config file
4. 🟡 **USB network adapter errors** - If not using, disable

### Informational (Can Ignore)

5. 🟢 **Intel i915 graphics warning** - Usually harmless
6. 🟢 **ACPI warnings** - Hardware compatibility, usually safe
7. 🟢 **Radarr ffprobe errors** - Will fix with root access changes

---

## 🚀 Complete Fix Script

Here's a complete script to fix all network service issues:

```bash
#!/bin/bash
# Network Service Fix Script
# Fixes boot errors and network service conflicts

echo "=== Fixing Network Service Conflicts ==="

# Disable systemd-networkd (conflicts with NetworkManager)
echo "Disabling systemd-networkd services..."
sudo systemctl disable systemd-networkd.service
sudo systemctl disable systemd-networkd.socket
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl stop systemd-networkd.service
sudo systemctl stop systemd-networkd.socket
sudo systemctl stop systemd-networkd-wait-online.service

# Option 1: Create minimal networking.service config
echo "Creating /etc/network/interfaces..."
sudo tee /etc/network/interfaces > /dev/null <<EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback
EOF

# Option 2: Or disable networking.service if not needed
# Uncomment the next line if you want to disable it:
# sudo systemctl disable networking.service

# Verify NetworkManager is enabled
echo "Verifying NetworkManager is enabled..."
sudo systemctl is-enabled NetworkManager
sudo systemctl status NetworkManager --no-pager | head -10

# Check current status
echo -e "\n=== Current Network Service Status ==="
systemctl list-unit-files --state=enabled | grep -E 'network|NetworkManager'

echo -e "\n=== Failed Services ==="
systemctl --failed

echo -e "\n=== Fix Complete ==="
echo "Please reboot to apply changes: sudo reboot"
echo "After reboot, verify with: systemctl --failed"
```

**To Use:**
```bash
# Save script to server
cat > /tmp/fix_network_services.sh << 'EOF'
# [paste script above]
EOF

chmod +x /tmp/fix_network_services.sh

# Run script
/tmp/fix_network_services.sh

# Reboot
sudo reboot
```

---

## ✅ Post-Fix Verification

After applying fixes and rebooting:

```bash
# Check failed services (should be empty or reduced)
systemctl --failed

# Verify network is working
ping -c 3 8.8.8.8
ip addr show

# Check boot logs for errors
journalctl -b -p err --no-pager | head -20

# Verify only NetworkManager is managing network
systemctl status NetworkManager
```

---

## 📚 Related Documentation

- [IMMEDIATE_ACTION_PLAN.md](IMMEDIATE_ACTION_PLAN.md) - Security fixes (includes Radarr ffprobe fix)
- [SERVER_AUDIT_ANALYSIS.md](SERVER_AUDIT_ANALYSIS.md) - Complete server audit

---

## 🎯 Priority

**This Week:**
1. Fix network service conflicts (prevents boot delays)
2. Disable failed systemd-networkd-wait-online service
3. Fix networking.service warnings

**This Month:**
4. Suppress ACPI warnings (optional)
5. Fix USB adapter issues (if needed)
6. Address Intel graphics warnings (if affecting Plex transcoding)

---

**Status**: ⚠️ **BOOT ERRORS FOUND - FIXES REQUIRED**
**Estimated Fix Time**: 15-30 minutes
**Risk**: Low (services can be re-enabled if needed)

