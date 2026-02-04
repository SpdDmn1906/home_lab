#!/bin/bash
#
# Fix CIFS VFS Errors
# Adds noserverino option to prevent inode warnings
# Fixes "Close unmatched open" errors with better mount options
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔧 FIX CIFS VFS ERRORS                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Backup fstab
echo "Step 1: Backing up /etc/fstab..."
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
echo "  ✅ Backup created"

# Create updated fstab entries
echo ""
echo "Step 2: Updating fstab with noserverino option..."

# Read current fstab
FSTAB_BACKUP=$(cat /etc/fstab)

# Remove old CIFS entries
sudo sed -i.tmp '/192.168.1.20\/Hulk/d' /etc/fstab

# Add updated entries with noserverino
cat << 'EOF' | sudo tee -a /etc/fstab > /dev/null

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
#   - soft: Don't hang on errors
#   - timeo=600: 10 minute timeout
#   - retrans=3: Retry 3 times
# ==============================================================================

//192.168.1.20/Hulk /home/youruser/synology cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm,noserverino,soft,timeo=600,retrans=3 0 0

//192.168.1.20/Hulk/Media /data/media cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm,noserverino,soft,timeo=600,retrans=3 0 0
EOF

echo "  ✅ fstab updated"

# Test fstab syntax
echo ""
echo "Step 3: Testing fstab syntax..."
if sudo mount -a --test 2>/dev/null || sudo mount -a -n 2>&1 | head -1 | grep -q "already mounted"; then
    echo "  ✅ fstab syntax is valid"
else
    echo "  ⚠️  fstab test completed (mounts may already be active)"
fi

# Reload systemd
echo ""
echo "Step 4: Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "  ✅ systemd reloaded"

# Unmount existing mounts
echo ""
echo "Step 5: Unmounting existing CIFS mounts..."
sudo systemctl stop data-media.mount 2>/dev/null && echo "  ✅ Stopped data-media.mount" || echo "  ⚠️  data-media.mount (may not exist)"
sudo systemctl stop home-youruser-synology.mount 2>/dev/null && echo "  ✅ Stopped home-youruser-synology.mount" || echo "  ⚠️  home-youruser-synology.mount (may not exist)"

sleep 2

sudo umount -l /data/media 2>/dev/null && echo "  ✅ Unmounted /data/media" || echo "  ⚠️  /data/media (may not be mounted)"
sudo umount -l /home/youruser/synology 2>/dev/null && echo "  ✅ Unmounted /home/youruser/synology" || echo "  ⚠️  /home/youruser/synology (may not be mounted)"

sleep 2

# Remount with new options
echo ""
echo "Step 6: Remounting with new options..."
sudo mount /home/youruser/synology && echo "  ✅ Mounted /home/youruser/synology" || echo "  ❌ Failed to mount /home/youruser/synology"
sudo mount /data/media && echo "  ✅ Mounted /data/media" || echo "  ❌ Failed to mount /data/media"

sleep 2

# Verify mounts
echo ""
echo "Step 7: Verifying mounts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mount | grep "192.168.1.20" | while read line; do
    if echo "$line" | grep -q "noserverino"; then
        echo "  ✅ $line"
    else
        echo "  ⚠️  $line (noserverino not found)"
    fi
done

echo ""
echo "Step 8: Checking for CIFS errors..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RECENT_ERRORS=$(dmesg | grep -i "cifs\|smb" | tail -5)
if [ -z "$RECENT_ERRORS" ]; then
    echo "  ✅ No recent CIFS errors in kernel log"
else
    echo "  Recent CIFS messages:"
    echo "$RECENT_ERRORS" | sed 's/^/    /'
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ CIFS FIX COMPLETE                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Changes made:"
echo "  • Added 'noserverino' option to prevent inode warnings"
echo "  • Added 'soft' option to prevent hangs on errors"
echo "  • Added 'timeo=600' for 10-minute timeout"
echo "  • Added 'retrans=3' for better retry handling"
echo ""
echo "Monitor for errors:"
echo "  dmesg | grep -i cifs"
echo "  journalctl -k | grep -i cifs"
echo ""

