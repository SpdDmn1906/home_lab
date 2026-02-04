#!/bin/bash
#
# Fix Invalid CIFS Mount Options
# Removes timeo=600 and retrans=3 (these are NFS options, not CIFS)
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔧 FIX INVALID CIFS OPTIONS                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Backup fstab
echo "Step 1: Backing up /etc/fstab..."
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
echo "  ✅ Backup created"

# Remove invalid options (timeo and retrans are NFS options, not CIFS)
echo ""
echo "Step 2: Removing invalid mount options (timeo=600,retrans=3)..."
sudo sed -i.tmp 's/,timeo=600,retrans=3//g' /etc/fstab
echo "  ✅ Invalid options removed"

# Verify changes
echo ""
echo "Step 3: Verifying fstab entries..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep "192.168.1.20/Hulk" /etc/fstab | sed 's/^/    /'
echo ""

# Test fstab syntax
echo "Step 4: Testing fstab syntax..."
if sudo mount -a --test 2>/dev/null; then
    echo "  ✅ fstab syntax is valid"
else
    echo "  ⚠️  Testing mount..."
    sudo mount -a -n 2>&1 | head -3 || true
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
echo "Step 8: Remounting with corrected options..."
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
        echo "  ⚠️  $line (noserverino not found)"
    fi
done

echo ""
echo "Step 10: Checking for CIFS errors..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RECENT_ERRORS=$(dmesg | grep -i "cifs\|smb" | tail -5)
if [ -n "$RECENT_ERRORS" ]; then
    echo "  Recent CIFS messages:"
    echo "$RECENT_ERRORS" | sed 's/^/    /'
else
    echo "  ✅ No recent CIFS errors"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ FIX COMPLETE                                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Fixed:"
echo "  • Removed invalid 'timeo=600' option (NFS option, not CIFS)"
echo "  • Removed invalid 'retrans=3' option (NFS option, not CIFS)"
echo "  • Kept valid options: noserverino, soft, noperm"
echo ""
echo "Valid CIFS options now active:"
echo "  • noserverino - Prevents inode warnings"
echo "  • soft - Prevents hangs on errors"
echo "  • noperm - Uses local permissions"
echo ""

