#!/usr/bin/env bash
#
# Fix Mac External Drive Sleep Issue
# Prevents external drives from sleeping, which causes Final Cut Pro libraries to relocate
#
# Usage:
#   ./fix_mac_drive_sleep_issue.sh [IP_ADDRESS] [USERNAME] [PASSWORD]
#   If IP_ADDRESS is provided, will SSH to that machine
#   If not provided, runs locally
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MAC_IP="${1:-}"
MAC_USER="${2:-}"
MAC_PASS="${3:-}"

# Functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Determine if we're running remotely or locally
USE_SSHPASS=false
if [[ -n "$MAC_IP" ]]; then
    if [[ -n "$MAC_USER" ]] && [[ -n "$MAC_PASS" ]]; then
        if command -v sshpass >/dev/null 2>&1; then
            USE_SSHPASS=true
            SSH_CMD="sshpass -p \"${MAC_PASS}\" ssh -o StrictHostKeyChecking=no ${MAC_USER}@${MAC_IP}"
            info "Running fix remotely on ${MAC_USER}@${MAC_IP} (using sshpass)"
        else
            error "sshpass not found. Install with: brew install hudochenkov/sshpass/sshpass"
            exit 1
        fi
    else
        SSH_CMD="ssh ${MAC_IP}"
        info "Running fix remotely on ${MAC_IP} (using SSH key)"
    fi
else
    SSH_CMD=""
    info "Running fix locally"
fi

# Function to run commands
run_cmd() {
    local cmd="$1"
    local description="${2:-}"

    if [[ -n "$description" ]]; then
        log "$description"
    fi

    if [[ -n "$SSH_CMD" ]]; then
        if [[ "$USE_SSHPASS" == "true" ]]; then
            sshpass -p "${MAC_PASS}" ssh -o StrictHostKeyChecking=no "${MAC_USER}@${MAC_IP}" "$cmd" 2>&1
        else
            ssh "${MAC_IP}" "$cmd" 2>&1
        fi
    else
        eval "$cmd" 2>&1
    fi
}

echo "=========================================="
echo "Fix Mac External Drive Sleep Issue"
echo "=========================================="
echo ""

# 1. Check current power management settings
log "=== Current Power Management Settings ==="
current_settings=$(run_cmd "pmset -g custom")
echo "$current_settings"
echo ""

# Check for disksleep setting
if echo "$current_settings" | grep -q "disksleep"; then
    disksleep_value=$(echo "$current_settings" | grep "disksleep" | awk '{print $2}')
    if [[ "$disksleep_value" != "0" ]]; then
        warning "disksleep is set to ${disksleep_value} minutes"
        warning "This will cause external drives to sleep after ${disksleep_value} minutes of inactivity"
        warning "When drives sleep, Final Cut Pro may lose access and create libraries on local drive"
    else
        success "disksleep is already disabled (set to 0)"
    fi
else
    warning "disksleep setting not found in current configuration"
fi
echo ""

# 2. Check if running as admin/root
log "=== Checking Permissions ==="
if [[ -n "$SSH_CMD" ]]; then
    if [[ "$USE_SSHPASS" == "true" ]]; then
        is_admin=$(sshpass -p "${MAC_PASS}" ssh -o StrictHostKeyChecking=no "${MAC_USER}@${MAC_IP}" "groups | grep -q admin && echo 'yes' || echo 'no'")
    else
        is_admin=$(ssh "${MAC_IP}" "groups | grep -q admin && echo 'yes' || echo 'no'")
    fi
else
    is_admin=$(groups | grep -q admin && echo "yes" || echo "no")
fi

if [[ "$is_admin" != "yes" ]]; then
    error "This script requires administrator privileges"
    error "Please run with sudo or as an administrator user"
    echo ""
    info "To fix manually, run on the Mac:"
    info "  sudo pmset -a disksleep 0"
    exit 1
fi
echo ""

# 3. Apply fix
log "=== Applying Fix ==="
info "Setting disksleep to 0 (never sleep external drives)"
info "This requires administrator privileges"
echo ""

# Note: pmset requires sudo, so we'll provide instructions
if [[ -n "$SSH_CMD" ]]; then
    warning "Cannot directly run sudo commands via SSH without passwordless sudo"
    warning "Please run the following command manually on the Mac:"
    echo ""
    echo "  sudo pmset -a disksleep 0"
    echo ""
    info "Or if you want to keep internal drives sleeping but not external:"
    echo "  sudo pmset -a disksleep 0"
    echo "  sudo pmset -a disablesleep 1  # Prevent system sleep (optional)"
    echo ""
else
    # Try to run locally
    if sudo -n true 2>/dev/null; then
        run_cmd "sudo pmset -a disksleep 0" "Disabling disk sleep"
        success "Disk sleep disabled successfully"
    else
        warning "Passwordless sudo not available"
        warning "Please run manually:"
        echo "  sudo pmset -a disksleep 0"
    fi
fi
echo ""

# 4. Additional recommendations
log "=== Additional Recommendations ==="
echo ""
info "1. System Settings → Energy Saver:"
info "   - Uncheck 'Put hard disks to sleep when possible'"
info "   - Set 'Prevent automatic sleeping' if needed"
echo ""
info "2. For Final Cut Pro specifically:"
info "   - Verify library location is set to '/Volumes/JC YT Biz'"
info "   - Check Final Cut Pro → Preferences → Library Locations"
info "   - Consider using a symlink if library path keeps changing"
echo ""
info "3. Monitor drive status:"
info "   - Use Activity Monitor to see if drive unmounts"
info "   - Check Console.app for disk arbitration events"
echo ""

# 5. Create a keep-alive script (optional)
log "=== Optional: Keep-Alive Script ==="
info "To prevent the drive from sleeping, you can create a script that"
info "periodically touches a file on the external drive:"
echo ""
cat << 'KEEPALIVE'
#!/bin/bash
# Keep external drive awake by touching a file every 5 minutes
while true; do
    if [ -d "/Volumes/JC YT Biz" ]; then
        touch "/Volumes/JC YT Biz/.keepalive" 2>/dev/null
    fi
    sleep 300  # 5 minutes
done
KEEPALIVE
echo ""
info "Save this as ~/keep_drive_awake.sh and run:"
info "  chmod +x ~/keep_drive_awake.sh"
info "  nohup ~/keep_drive_awake.sh &"
echo ""

success "Fix instructions provided. Please run 'sudo pmset -a disksleep 0' on the Mac."

