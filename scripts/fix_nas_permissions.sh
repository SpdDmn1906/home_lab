#!/bin/bash
#
# Fix NAS Mount Permissions
# Run this directly on the server: ssh youruser@192.168.1.11
# Then: bash ~/fix_nas_permissions.sh
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔧 FIX NAS MOUNT PERMISSIONS                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "This will fix CIFS mount permissions to allow non-sudo file operations."
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."

echo ""
echo "Step 1: Stopping systemd mount services..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo systemctl stop data-media.mount 2>/dev/null && echo "  ✅ Stopped data-media.mount" || echo "  ⚠️  data-media.mount"
sudo systemctl stop home-youruser-synology.mount 2>/dev/null && echo "  ✅ Stopped home-youruser-synology.mount" || echo "  ⚠️  synology.mount"
sudo systemctl stop home-youruser-synology.automount 2>/dev/null && echo "  ✅ Stopped synology.automount" || echo "  ⚠️  synology.automount"

echo ""
echo "Step 2: Force unmounting all NAS mounts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo umount -l /data/media 2>/dev/null && echo "  ✅ Unmounted /data/media" || echo "  ⚠️  /data/media"
sudo umount -l /home/youruser/synology 2>/dev/null && echo "  ✅ Unmounted ~/synology" || echo "  ⚠️  ~/synology"

sleep 3

remaining=$(mount | grep -c "192.168.1.20")
if [ "$remaining" -eq 0 ]; then
    echo "  ✅ All NAS mounts cleared"
else
    echo "  ⚠️  $remaining mounts still active (will try to continue)"
fi

echo ""
echo "Step 3: Backing up and updating /etc/fstab..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Backup fstab
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
echo "  ✅ Backed up /etc/fstab"

# Remove old NAS entries
sudo sed -i.old '/192.168.1.20/d' /etc/fstab
echo "  ✅ Removed old NAS entries"

# Add new entries with proper permissions
cat << 'EOFFSTAB' | sudo tee -a /etc/fstab > /dev/null

# ==============================================================================
# NAS Mounts - CIFS with full user permissions
# ==============================================================================
# User: youruser (uid=1000, gid=1004)
# Permissions: file_mode=0775, dir_mode=0775 (rwxrwxr-x)
# Options:
#   - noperm: Don't enforce server permissions (use local uid/gid/modes)
#   - iocharset=utf8: Handle international characters
#   - vers=3.0: Use SMB3 protocol
# ==============================================================================

//192.168.1.20/Hulk /home/youruser/synology cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm 0 0

//192.168.1.20/Hulk/Media /data/media cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm 0 0

EOFFSTAB

echo "  ✅ Added new fstab entries"

echo ""
echo "Step 4: Reloading systemd and remounting..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo systemctl daemon-reload
echo "  ✅ Reloaded systemd"

sudo mount /home/youruser/synology && echo "  ✅ Mounted ~/synology" || echo "  ❌ Failed: ~/synology"
sudo mount /data/media && echo "  ✅ Mounted /data/media" || echo "  ❌ Failed: /data/media"

sleep 2

echo ""
echo "Step 5: Verifying new permissions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Mount options:"
mount | grep 192.168.1.20 | while read line; do
    echo "  $line"
done

echo ""
echo "Directory ownership:"
ls -ld ~/synology/Media/Movies
ls -ld /data/media/Movies

echo ""
echo "Step 6: Testing write permissions (WITHOUT sudo)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test ~/synology
test_dir_synology=~/"synology/Media/Movies/.test_dir_$$"
mkdir "$test_dir_synology" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✅ ~/synology: Can create directories"
    rmdir "$test_dir_synology"
else
    echo "  ❌ ~/synology: Cannot create directories"
fi

test_file_synology=~/synology/Media/Movies/.test_file_$$
touch "$test_file_synology" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✅ ~/synology: Can create files"
    rm "$test_file_synology"
else
    echo "  ❌ ~/synology: Cannot create files"
fi

# Test /data/media
test_dir_data="/data/media/Movies/.test_dir_$$"
mkdir "$test_dir_data" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✅ /data/media: Can create directories"
    rmdir "$test_dir_data"
else
    echo "  ❌ /data/media: Cannot create directories"
fi

test_file_data="/data/media/Movies/.test_file_$$"
touch "$test_file_data" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✅ /data/media: Can create files"
    rm "$test_file_data"
else
    echo "  ❌ /data/media: Cannot create files"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ PERMISSION FIX COMPLETE                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [ -f ~/synology/Media/Movies/.test_file_$$ ] || [ -f /data/media/Movies/.test_file_$$ ]; then
    echo "⚠️  PERMISSIONS STILL NOT WORKING"
    echo ""
    echo "This usually means:"
    echo "  1. Synology NAS has strict permissions on the share"
    echo "  2. User 'SCAdmin' doesn't have full permissions"
    echo "  3. The share is configured as read-only"
    echo ""
    echo "To fix:"
    echo "  1. Open Synology DSM: http://192.168.1.20:5000"
    echo "  2. Go to: Control Panel → Shared Folder"
    echo "  3. Edit 'Hulk' share → Permissions"
    echo "  4. Ensure 'SCAdmin' has 'Read/Write' permissions"
    echo "  5. Run this script again"
else
    echo "✅ SUCCESS! You can now create/modify files without sudo"
    echo ""
    echo "Next step: Run the Rocky collection split script"
fi

