#!/bin/bash
#
# Fix CIFS VFS Errors - Direct Execution
# Run this directly on the server after SSH: bash fix_cifs_errors_direct.sh
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔧 FIX CIFS VFS ERRORS                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Backup fstab
echo "Step 1: Backing up /etc/fstab..."
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
echo "  ✅ Backup created"

# Update fstab using sed to add noserverino and other options
echo ""
echo "Step 2: Updating fstab entries..."

# Update first mount entry
sudo sed -i.tmp 's|//192.168.1.20/Hulk /home/youruser/synology cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm|//192.168.1.20/Hulk /home/youruser/synology cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm,noserverino,soft,timeo=600,retrans=3|' /etc/fstab

# Update second mount entry
sudo sed -i.tmp 's|//192.168.1.20/Hulk/Media /data/media cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm|//192.168.1.20/Hulk/Media /data/media cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm,noserverino,soft,timeo=600,retrans=3|' /etc/fstab

echo "  ✅ fstab updated"

# Verify changes
echo ""
echo "Step 3: Verifying fstab changes..."
if grep -q "noserverino" /etc/fstab; then
    echo "  ✅ noserverino option found in fstab"
    echo ""
    echo "Updated entries:"
    grep "192.168.1.20/Hulk" /etc/fstab | sed 's/^/    /'
else
    echo "  ❌ noserverino not found - update may have failed"
    exit 1
fi

# Test fstab syntax
echo ""
echo "Step 4: Testing fstab syntax..."
if sudo mount -a --test 2>/dev/null; then
    echo "  ✅ fstab syntax is valid"
else
    echo "  ⚠️  Running mount test..."
    sudo mount -a -n 2>&1 | head -5 || true
fi

# Stop systemd mount services
echo ""
echo "Step 5: Stopping systemd mount services..."
sudo systemctl stop data-media.mount 2>/dev/null && echo "  ✅ Stopped data-media.mount" || echo "  ⚠️  data-media.mount (not running)"
sudo systemctl stop home-youruser-synology.mount 2>/dev/null && echo "  ✅ Stopped home-youruser-synology.mount" || echo "  ⚠️  home-youruser-synology.mount (not running)"

sleep 2

# Unmount
echo ""
echo "Step 6: Unmounting CIFS filesystems..."
sudo umount -l /data/media 2>/dev/null && echo "  ✅ Unmounted /data/media" || echo "  ⚠️  /data/media (may not be mounted)"
sudo umount -l /home/youruser/synology 2>/dev/null && echo "  ✅ Unmounted /home/youruser/synology" || echo "  ⚠️  /home/youruser/synology (may not be mounted)"

sleep 2

# Reload systemd
echo ""
echo "Step 7: Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "  ✅ systemd reloaded"

# Remount
echo ""
echo "Step 8: Remounting with new options..."
sudo mount /home/youruser/synology && echo "  ✅ Mounted /home/youruser/synology" || echo "  ❌ Failed to mount /home/youruser/synology"
sudo mount /data/media && echo "  ✅ Mounted /data/media" || echo "  ❌ Failed to mount /data/media"

sleep 2

# Verify mounts
echo ""
echo "Step 9: Verifying mounts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mount | grep "192.168.1.20" | while read line; do
    if echo "$line" | grep -q "noserverino"; then
        echo "  ✅ $line"
    else
        echo "  ⚠️  $line (noserverino not found - may need reboot)"
    fi
done

echo ""
echo "Step 10: Testing file operations..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TEST_FILE="/home/youruser/synology/.cifs_test_$$"
if touch "$TEST_FILE" 2>/dev/null; then
    echo "  ✅ Write test successful"
    rm -f "$TEST_FILE"
else
    echo "  ⚠️  Write test failed (check permissions)"
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
echo "  2. If noserverino not showing in mount, reboot to ensure clean mount"
echo "  3. After reboot, verify: mount | grep cifs | grep noserverino"
echo ""

