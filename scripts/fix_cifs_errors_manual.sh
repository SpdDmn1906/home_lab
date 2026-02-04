#!/bin/bash
#
# Fix CIFS VFS Errors - Manual Execution Script
# Run this directly on the server: ssh youruser@192.168.1.11
# Then: bash ~/fix_cifs_errors_manual.sh
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔧 FIX CIFS VFS ERRORS                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Backup fstab
echo "Step 1: Backing up /etc/fstab..."
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
echo "  ✅ Backup created: /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)"

# Create temporary fstab with updated entries
echo ""
echo "Step 2: Creating updated fstab entries..."

# Read current fstab and remove old CIFS entries
TMP_FSTAB=$(mktemp)
grep -v "192.168.1.20/Hulk" /etc/fstab > "$TMP_FSTAB"

# Add updated entries
cat >> "$TMP_FSTAB" << 'EOF'

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

//192.168.1.20/Hulk /home/youruser/synology cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm,noserverino,soft,timeo=600,retrans=3 0 0

//192.168.1.20/Hulk/Media /data/media cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm,noserverino,soft,timeo=600,retrans=3 0 0
EOF

# Show diff
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Changes to be made:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
diff -u /etc/fstab "$TMP_FSTAB" | grep -E "^\+|^\-" | grep -v "^+++\|^---" | head -20
echo ""

read -p "Apply these changes? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    rm "$TMP_FSTAB"
    exit 1
fi

# Apply changes
sudo cp "$TMP_FSTAB" /etc/fstab
rm "$TMP_FSTAB"
echo "  ✅ fstab updated"

# Test fstab syntax
echo ""
echo "Step 3: Testing fstab syntax..."
if sudo mount -a --test 2>/dev/null; then
    echo "  ✅ fstab syntax is valid"
else
    echo "  ⚠️  Running mount test..."
    sudo mount -a -n 2>&1 | head -5
fi

# Stop systemd mount services
echo ""
echo "Step 4: Stopping systemd mount services..."
sudo systemctl stop data-media.mount 2>/dev/null && echo "  ✅ Stopped data-media.mount" || echo "  ⚠️  data-media.mount (not running)"
sudo systemctl stop home-youruser-synology.mount 2>/dev/null && echo "  ✅ Stopped home-youruser-synology.mount" || echo "  ⚠️  home-youruser-synology.mount (not running)"

sleep 2

# Unmount
echo ""
echo "Step 5: Unmounting CIFS filesystems..."
sudo umount -l /data/media 2>/dev/null && echo "  ✅ Unmounted /data/media" || echo "  ⚠️  /data/media (may not be mounted)"
sudo umount -l /home/youruser/synology 2>/dev/null && echo "  ✅ Unmounted /home/youruser/synology" || echo "  ⚠️  /home/youruser/synology (may not be mounted)"

sleep 2

# Reload systemd
echo ""
echo "Step 6: Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "  ✅ systemd reloaded"

# Remount
echo ""
echo "Step 7: Remounting with new options..."
sudo mount /home/youruser/synology && echo "  ✅ Mounted /home/youruser/synology" || echo "  ❌ Failed to mount /home/youruser/synology"
sudo mount /data/media && echo "  ✅ Mounted /data/media" || echo "  ❌ Failed to mount /data/media"

sleep 2

# Verify mounts
echo ""
echo "Step 8: Verifying mounts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mount | grep "192.168.1.20" | while read line; do
    if echo "$line" | grep -q "noserverino"; then
        echo "  ✅ $line"
    else
        echo "  ⚠️  $line (noserverino not found - may need reboot)"
    fi
done

echo ""
echo "Step 9: Testing file operations..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TEST_FILE="/home/youruser/synology/.cifs_test_$$"
if touch "$TEST_FILE" 2>/dev/null; then
    echo "  ✅ Write test successful"
    rm -f "$TEST_FILE"
else
    echo "  ⚠️  Write test failed (check permissions)"
fi

echo ""
echo "Step 10: Checking for CIFS errors..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RECENT_ERRORS=$(dmesg | grep -i "cifs\|smb" | tail -10)
if echo "$RECENT_ERRORS" | grep -q "noserverino\|Autodisabling"; then
    echo "  ⚠️  Old errors still in log (will clear after reboot):"
    echo "$RECENT_ERRORS" | sed 's/^/    /'
else
    echo "  ✅ No new CIFS errors"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ CIFS FIX COMPLETE                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Changes applied:"
echo "  • Added 'noserverino' option to prevent inode warnings"
echo "  • Added 'soft' option to prevent hangs on errors"
echo "  • Added 'timeo=600' for 10-minute timeout"
echo "  • Added 'retrans=3' for better retry handling"
echo ""
echo "Next steps:"
echo "  1. Monitor for errors: dmesg | grep -i cifs"
echo "  2. If errors persist, reboot to ensure clean mount"
echo "  3. After reboot, verify: mount | grep cifs"
echo ""

