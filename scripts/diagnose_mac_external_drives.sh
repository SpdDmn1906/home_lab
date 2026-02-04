#!/usr/bin/env bash
#
# Mac External Drive Disconnection Diagnostic Script
# Checks logs and system information for external drive disconnection issues
#
# Usage:
#   ./diagnose_mac_external_drives.sh [IP_ADDRESS] [USERNAME] [PASSWORD]
#   If IP_ADDRESS is provided, will SSH to that machine
#   If USERNAME and PASSWORD are provided, will use sshpass
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
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUTPUT_DIR="${HOME}/mac_drive_diagnostics"
LOG_FILE="${OUTPUT_DIR}/diagnostic_${TIMESTAMP}.log"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1" | tee -a "$LOG_FILE"
}

# Determine if we're running remotely or locally
USE_SSHPASS=false
if [[ -n "$MAC_IP" ]]; then
    if [[ -n "$MAC_USER" ]] && [[ -n "$MAC_PASS" ]]; then
        # Check if sshpass is available
        if command -v sshpass >/dev/null 2>&1; then
            USE_SSHPASS=true
            SSH_CMD="sshpass -p \"${MAC_PASS}\" ssh -o StrictHostKeyChecking=no ${MAC_USER}@${MAC_IP}"
            info "Running diagnostics remotely on ${MAC_USER}@${MAC_IP} (using sshpass)"
        else
            error "sshpass not found. Install with: brew install hudochenkov/sshpass/sshpass"
            error "Or run without password (requires SSH key setup)"
            exit 1
        fi
    else
        SSH_CMD="ssh ${MAC_IP}"
        info "Running diagnostics remotely on ${MAC_IP} (using SSH key)"
    fi
else
    SSH_CMD=""
    info "Running diagnostics locally"
fi

# Function to run commands (either locally or via SSH)
run_cmd() {
    local cmd="$1"
    local description="${2:-}"

    if [[ -n "$description" ]]; then
        log "$description"
    fi

    if [[ -n "$SSH_CMD" ]]; then
        if [[ "$USE_SSHPASS" == "true" ]]; then
            # For sshpass, we need to properly escape the command
            sshpass -p "${MAC_PASS}" ssh -o StrictHostKeyChecking=no "${MAC_USER}@${MAC_IP}" "$cmd" 2>&1 | tee -a "$LOG_FILE"
        else
            ssh "${MAC_IP}" "$cmd" 2>&1 | tee -a "$LOG_FILE"
        fi
    else
        eval "$cmd" 2>&1 | tee -a "$LOG_FILE"
    fi
    echo "" | tee -a "$LOG_FILE"
}

# Function to check if command exists remotely
check_remote_cmd() {
    local cmd="$1"
    if [[ -n "$SSH_CMD" ]]; then
        if [[ "$USE_SSHPASS" == "true" ]]; then
            sshpass -p "${MAC_PASS}" ssh -o StrictHostKeyChecking=no "${MAC_USER}@${MAC_IP}" "command -v $cmd >/dev/null 2>&1 || test -x $cmd" && return 0 || return 1
        else
            ssh "${MAC_IP}" "command -v $cmd >/dev/null 2>&1 || test -x $cmd" && return 0 || return 1
        fi
    else
        command -v "$cmd" >/dev/null 2>&1 || test -x "$cmd" && return 0 || return 1
    fi
}

echo "=========================================="
echo "Mac External Drive Disconnection Diagnostics"
echo "=========================================="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
if [[ -n "$MAC_IP" ]]; then
    echo "Target: ${MAC_IP}"
else
    echo "Target: Local machine"
fi
echo "Output: ${LOG_FILE}"
echo "=========================================="
echo ""

# 1. System Information
log "=== System Information ==="
run_cmd "uname -a" "System version"
run_cmd "sw_vers" "macOS version"
run_cmd "uptime" "System uptime"
echo ""

# 2. USB Device Information
log "=== USB Device Information ==="
if check_remote_cmd "system_profiler"; then
    run_cmd "system_profiler SPUSBDataType" "USB devices and hubs"
else
    warning "system_profiler not available"
fi
echo ""

# 3. Disk Information
log "=== Disk Information ==="
run_cmd "diskutil list" "All disks"
run_cmd "diskutil info -all" "Detailed disk information"
echo ""

# 4. Mounted External Drives
log "=== Mounted External Drives ==="
run_cmd "mount | grep -E '(disk|external|usb)'" "Mounted external drives"
run_cmd "df -h | grep -E '(disk|external|usb)'" "External drive usage"
echo ""

# 5. Recent USB Disconnection Events (last 24 hours)
log "=== USB Disconnection Events (Last 24 Hours) ==="
if check_remote_cmd "/usr/bin/log"; then
    run_cmd "/usr/bin/log show --predicate 'subsystem == \"com.apple.iokit.usb\"' --last 24h --style compact | grep -iE '(disconnect|remove|eject|error|fail)' | tail -50" "USB disconnection events"

    # More detailed USB errors
    run_cmd "/usr/bin/log show --predicate 'subsystem == \"com.apple.iokit.usb\"' --last 24h --style compact | grep -iE '(error|fail|timeout|reset)' | tail -50" "USB errors and timeouts"
else
    warning "log command not available (requires macOS 10.12+)"
fi
echo ""

# 6. Disk Arbitration Events (last 24 hours)
log "=== Disk Arbitration Events (Last 24 Hours) ==="
if check_remote_cmd "/usr/bin/log"; then
    run_cmd "/usr/bin/log show --predicate 'subsystem == \"com.apple.diskarbitrationd\"' --last 24h --style compact | grep -iE '(disappear|unmount|eject|remove|error)' | tail -50" "Disk arbitration events"

    # Disk errors
    run_cmd "/usr/bin/log show --predicate 'subsystem == \"com.apple.diskarbitrationd\"' --last 24h --style compact | grep -iE '(error|fail|timeout)' | tail -50" "Disk arbitration errors"
else
    warning "log command not available"
fi
echo ""

# 7. IOKit Events (last 24 hours)
log "=== IOKit Events (Last 24 Hours) ==="
if check_remote_cmd "/usr/bin/log"; then
    run_cmd "/usr/bin/log show --predicate 'subsystem == \"com.apple.iokit.iohid\"' --last 24h --style compact | grep -iE '(disconnect|remove|error)' | tail -30" "IOKit HID events"

    run_cmd "/usr/bin/log show --predicate 'subsystem == \"com.apple.iokit.storage\"' --last 24h --style compact | grep -iE '(disconnect|remove|error|fail)' | tail -50" "IOKit storage events"
else
    warning "log command not available"
fi
echo ""

# 8. Kernel Extension and Driver Issues
log "=== Kernel Extension Issues ==="
if check_remote_cmd "/usr/bin/log"; then
    run_cmd "/usr/bin/log show --predicate 'subsystem == \"com.apple.kernel\"' --last 24h --style compact | grep -iE '(usb|disk|storage|driver|kext)' | tail -30" "Kernel USB/disk events"
else
    warning "log command not available"
fi
echo ""

# 9. Power Management Events
log "=== Power Management Events (Last 24 Hours) ==="
if check_remote_cmd "/usr/bin/log"; then
    run_cmd "/usr/bin/log show --predicate 'subsystem == \"com.apple.powermanagement\"' --last 24h --style compact | grep -iE '(usb|sleep|wake|power)' | tail -30" "Power management events"
else
    warning "log command not available"
fi
echo ""

# 10. System Errors Related to Disks
log "=== System Errors Related to Disks (Last 24 Hours) ==="
if check_remote_cmd "/usr/bin/log"; then
    run_cmd "/usr/bin/log show --last 24h --style compact | grep -iE '(disk.*error|usb.*error|storage.*error|external.*disconnect)' | tail -50" "General disk/USB errors"
else
    warning "log command not available"
fi
echo ""

# 11. Check for diskutil errors
log "=== Disk Utility Errors ==="
run_cmd "diskutil list | grep -E 'disk[0-9]+' | while read line; do disk=\$(echo \$line | awk '{print \$NF}'); echo \"Checking \$disk...\"; diskutil verifyDisk \$disk 2>&1 | head -20 || true; done" "Disk verification status"
echo ""

# 12. USB Hub Information (if available)
log "=== USB Hub Details ==="
if check_remote_cmd "system_profiler"; then
    run_cmd "system_profiler SPUSBDataType | grep -A 20 -i 'hub'" "USB hub information"
else
    warning "system_profiler not available"
fi
echo ""

# 13. Check for USB power issues
log "=== USB Power Information ==="
if check_remote_cmd "system_profiler"; then
    run_cmd "system_profiler SPUSBDataType | grep -iE '(current|power|ma|voltage)'" "USB power consumption"
else
    warning "system_profiler not available"
fi
echo ""

# 14. Recent Console Messages (alternative method)
log "=== Recent Console Messages (Last 2 Hours) ==="
if check_remote_cmd "/usr/bin/log"; then
    run_cmd "/usr/bin/log show --last 2h --style compact | grep -iE '(usb|disk|external|storage).*(disconnect|remove|eject|error|fail)' | tail -50" "Recent console messages"
else
    warning "log command not available"
fi
echo ""

# 15. Check disk activity and I/O errors
log "=== Disk I/O Statistics ==="
if check_remote_cmd "iostat"; then
    run_cmd "iostat -w 1 -c 3" "Disk I/O statistics"
else
    info "iostat not available (install via: brew install sysstat)"
fi
echo ""

# Summary
log "=== Diagnostic Summary ==="
echo ""
info "Diagnostic complete. Review the log file for details:"
info "  ${LOG_FILE}"
echo ""
info "Key things to look for:"
info "  1. USB disconnection events in IOKit logs"
info "  2. Disk arbitration errors"
info "  3. Power management issues (USB power drops)"
info "  4. USB hub errors or power consumption issues"
info "  5. Kernel errors related to USB/disk drivers"
echo ""
info "Common causes of external drive disconnections:"
info "  - Insufficient USB power (especially with hubs)"
info "  - Faulty USB hub or cable"
info "  - USB port issues"
info "  - Power management settings putting USB to sleep"
info "  - Driver/kext issues"
info "  - Physical connection problems"
echo ""

success "Diagnostics saved to: ${LOG_FILE}"

