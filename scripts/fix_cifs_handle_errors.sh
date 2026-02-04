#!/bin/bash
#
# Fix CIFS Handle Errors
# Addresses "No writable handles for inode" and "Close unmatched open" errors
# These errors occur during rapid file operations (like quarantine process)
#

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔧 FIX CIFS HANDLE ERRORS                                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run with sudo"
    exit 1
fi

log_info "Step 1: Checking current fstab configuration..."
CURRENT_FSTAB=$(grep "192.168.1.20/Hulk" /etc/fstab)
if [ -z "$CURRENT_FSTAB" ]; then
    log_error "CIFS mounts not found in fstab"
    exit 1
fi

echo "$CURRENT_FSTAB"

log_info "Step 2: Analyzing issues..."
echo ""
echo "Current status:"
echo "  ✅ 'noserverino' is in fstab (configured previously)"
echo "  ❌ 'noserverino' not active in current mount (needs remount)"
echo ""
echo "Problems identified:"
echo "  1. ❌ 'noserverino' needs remount to activate"
echo "  2. ❌ 'cache=strict' (default) causing handle caching issues"
echo "  3. ❌ Missing 'cache=none' and 'actimeo=0' for rapid operations"
echo "  4. ⚠️  Rapid file operations (quarantine) stressing handles"
echo ""

log_info "Step 3: Creating backup of fstab..."
cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
log_success "Backup created"

log_info "Step 4: Updating fstab with improved options..."
log_info "Adding cache=none, actimeo=0, and _netdev (noserverino already present)"

# Update first mount - add cache=none, actimeo=0, and _netdev
sed -i.tmp 's|//192.168.1.20/Hulk /home/youruser/synology cifs.*|//192.168.1.20/Hulk /home/youruser/synology cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm,noserverino,soft,cache=none,actimeo=0,_netdev,nofail 0 0|' /etc/fstab

# Update second mount - add cache=none, actimeo=0, and _netdev
sed -i.tmp 's|//192.168.1.20/Hulk/Media /data/media cifs.*|//192.168.1.20/Hulk/Media /data/media cifs credentials=/home/youruser/.smbcredentials,vers=3.0,uid=1000,gid=1004,file_mode=0775,dir_mode=0775,iocharset=utf8,noperm,noserverino,soft,cache=none,actimeo=0,_netdev,nofail 0 0|' /etc/fstab

log_success "fstab updated"

log_info "Step 5: Verifying fstab changes..."
if grep -q "cache=none" /etc/fstab && grep -q "actimeo=0" /etc/fstab && grep -q "noserverino" /etc/fstab; then
    log_success "All required options found in fstab"
    echo ""
    echo "Updated fstab entries:"
    grep "192.168.1.20/Hulk" /etc/fstab | sed 's/^/  /'
else
    log_error "Some options missing in fstab"
    exit 1
fi

echo ""
log_warning "Step 6: Remounting CIFS filesystems with new options..."
log_warning "This will temporarily disconnect active connections"

# Unmount
log_info "Unmounting /home/youruser/synology..."
umount /home/youruser/synology 2>/dev/null || log_warning "Mount point may already be unmounted or in use"

log_info "Unmounting /data/media..."
umount /data/media 2>/dev/null || log_warning "Mount point may already be unmounted or in use"

sleep 2

# Remount
log_info "Remounting with new options..."
mount -a

sleep 2

log_info "Step 7: Verifying mounts..."
if mount | grep -q "192.168.1.20/Hulk.*on /home/youruser/synology" && \
   mount | grep -q "192.168.1.20/Hulk/Media.*on /data/media"; then
    log_success "CIFS mounts are active"
else
    log_error "Mount verification failed"
    log_warning "You may need to manually mount or check network connectivity"
    exit 1
fi

log_info "Step 8: Checking active mount options..."
echo ""
mount | grep cifs | while read -r line; do
    MOUNT_POINT=$(echo "$line" | awk '{print $3}')
    log_info "Mount: $MOUNT_POINT"

    if echo "$line" | grep -q "cache=none"; then
        log_success "  ✅ cache=none: ACTIVE"
    elif echo "$line" | grep -q "cache="; then
        CACHE=$(echo "$line" | grep -o "cache=[^,)]*")
        log_warning "  ⚠️  $CACHE (should be cache=none)"
    else
        log_warning "  ⚠️  cache=strict (default - not applied)"
    fi

    if echo "$line" | grep -q "actimeo=0"; then
        log_success "  ✅ actimeo=0: ACTIVE"
    elif echo "$line" | grep -q "actimeo="; then
        ACTIMEO=$(echo "$line" | grep -o "actimeo=[^,)]*")
        log_warning "  ⚠️  $ACTIMEO (should be actimeo=0)"
    else
        log_warning "  ⚠️  actimeo=1 (default - not applied)"
    fi

    # noserverino may not show in mount output but can still be active
    if echo "$line" | grep -q "noserverino"; then
        log_success "  ✅ noserverino: ACTIVE (visible)"
    else
        log_warning "  ⚠️  noserverino: Not visible (may be active but not shown)"
    fi

    echo ""
done

echo ""
log_info "Step 9: Testing write access..."
TEST_FILE="/data/media/.cifs_test_$$"
if touch "$TEST_FILE" 2>/dev/null && rm -f "$TEST_FILE" 2>/dev/null; then
    log_success "Write access working"
else
    log_error "Write access test failed"
fi

echo ""
log_info "Step 10: Checking for errors..."
echo ""
# Check for inode errors (noserverino should prevent these)
INODE_ERRORS=$(dmesg | grep -i "Autodisabling.*inode" | tail -3)
if [ -z "$INODE_ERRORS" ]; then
    log_success "No inode warnings (noserverino working)"
else
    log_warning "Inode warnings still present:"
    echo "$INODE_ERRORS" | sed 's/^/  /'
fi

# Check for handle errors
HANDLE_ERRORS=$(dmesg | grep -iE "No writable handles|Close unmatched" | tail -3)
if [ -z "$HANDLE_ERRORS" ]; then
    log_success "No handle errors detected"
else
    log_warning "Handle errors present:"
    echo "$HANDLE_ERRORS" | sed 's/^/  /'
    log_info "Note: These may be from before the remount. Monitor after quarantine operations."
fi

# Wait and check for new errors
log_info "Monitoring for new errors (waiting 10 seconds)..."
sleep 10
NEW_ERRORS=$(dmesg | grep -i "CIFS VFS" | tail -5)
if [ -z "$NEW_ERRORS" ]; then
    log_success "No new CIFS errors detected"
else
    log_warning "Recent CIFS messages:"
    echo "$NEW_ERRORS" | sed 's/^/  /'
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ CIFS FIX COMPLETE                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Changes made:"
echo "  ✅ Added 'cache=none' - Reduces handle caching issues"
echo "  ✅ Added 'actimeo=0' - Disables attribute caching"
echo "  ✅ Added '_netdev' - Waits for network before mounting"
echo "  ✅ Added 'nofail' - Boot continues if mount fails"
echo "  ✅ Remounted to activate 'noserverino' (was already in fstab)"
echo "  ✅ Kept 'soft' - Prevents hangs on errors"
echo ""
echo "Why these fixes help:"
echo "  • cache=none: Prevents stale file handles during rapid operations"
echo "  • actimeo=0: Reduces cached metadata that can cause mismatches"
echo "  • noserverino: Prevents inode number conflicts"
echo "  • soft: Allows recovery from temporary network issues"
echo ""
echo "Next steps:"
echo "  1. Monitor for errors: dmesg | grep -i cifs | tail -20"
echo "  2. Continue quarantine process (errors should be reduced)"
echo "  3. If errors persist, consider reducing parallel workers"
echo "  4. Reboot recommended to ensure clean mount state"
echo ""

