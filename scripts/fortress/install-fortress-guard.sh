#!/bin/bash
# Install / uninstall Plex Fortress Guard
# Run locally on server or remotely via SSH from Mac

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/homelab/scripts/fortress"
REMOTE_HOST="youruser@192.168.1.11"
SYSTEMD_DIR="/etc/systemd/system"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()     { echo -e "[$(date '+%H:%M:%S')] $*"; }
success() { echo -e "${GREEN}OK${NC} $*"; }
error()   { echo -e "${RED}ERROR${NC} $*" >&2; }

check_deps() {
    local missing=()
    for cmd in curl iptables dig; do
        command -v "$cmd" >/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing: ${missing[*]}"
        exit 1
    fi
}

install_local() {
    log "Installing Plex Fortress Guard..."
    check_deps

    sudo mkdir -p "$INSTALL_DIR" /var/log/homelab

    sudo cp "$SCRIPT_DIR/plex-fortress-guard.sh" "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/plex-fortress-guard.sh"

    # install systemd units with correct path
    for unit in plex-fortress-guard.service plex-fortress-guard.timer; do
        sudo cp "$SCRIPT_DIR/$unit" "$SYSTEMD_DIR/"
    done
    sudo sed -i "s|ExecStart=.*|ExecStart=$INSTALL_DIR/plex-fortress-guard.sh|" \
        "$SYSTEMD_DIR/plex-fortress-guard.service"

    sudo systemctl daemon-reload
    sudo systemctl enable --now plex-fortress-guard.timer

    success "Installed. Timer active."
    echo "  Status:  systemctl status plex-fortress-guard.timer"
    echo "  Logs:    journalctl -u plex-fortress-guard -f"
    echo "  Manual:  sudo $INSTALL_DIR/plex-fortress-guard.sh --status"
}

install_remote() {
    log "Deploying to $REMOTE_HOST..."
    scp -q "$SCRIPT_DIR"/plex-fortress-guard.{sh,service,timer} \
           "$SCRIPT_DIR/install-fortress-guard.sh" \
           "$REMOTE_HOST:/tmp/"
    ssh "$REMOTE_HOST" "sudo bash /tmp/install-fortress-guard.sh --local"
}

uninstall() {
    log "Uninstalling Plex Fortress Guard..."
    sudo systemctl stop plex-fortress-guard.timer 2>/dev/null || true
    sudo systemctl disable plex-fortress-guard.timer 2>/dev/null || true
    sudo rm -f "$SYSTEMD_DIR"/plex-fortress-guard.{service,timer}
    sudo systemctl daemon-reload

    # clear any active iptables rules
    if [[ -x "$INSTALL_DIR/plex-fortress-guard.sh" ]]; then
        sudo "$INSTALL_DIR/plex-fortress-guard.sh" --clear
    fi

    success "Uninstalled and all rules cleared"
}

case "${1:---remote}" in
    --local)     install_local ;;
    --remote)    install_remote ;;
    --uninstall) uninstall ;;
    *)           echo "Usage: $0 [--local|--remote|--uninstall]" ;;
esac
