#!/bin/bash
# System Cleanup Script
# Cleans up Docker, logs, and temporary files

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Docker cleanup
cleanup_docker() {
    log "Cleaning up Docker resources..."

    # Remove stopped containers
    STOPPED=$(docker ps -a -q -f status=exited)
    if [ -n "$STOPPED" ]; then
        docker rm $STOPPED
        log "Removed stopped containers"
    else
        log "No stopped containers to remove"
    fi

    # Remove unused images
    UNUSED_IMAGES=$(docker images -q -f dangling=true)
    if [ -n "$UNUSED_IMAGES" ]; then
        docker rmi $UNUSED_IMAGES
        log "Removed unused images"
    else
        log "No unused images to remove"
    fi

    # Remove unused volumes (be careful!)
    # Uncomment if you want to remove unused volumes
    # UNUSED_VOLUMES=$(docker volume ls -q -f dangling=true)
    # if [ -n "$UNUSED_VOLUMES" ]; then
    #     docker volume rm $UNUSED_VOLUMES
    #     log "Removed unused volumes"
    # fi

    # Prune system
    docker system prune -f
    log "Docker cleanup complete"
}

# Log cleanup
cleanup_logs() {
    log "Cleaning up logs..."

    # Journal logs (systemd)
    if command -v journalctl &> /dev/null; then
        journalctl --vacuum-time=30d
        log "Cleaned systemd logs (kept last 30 days)"
    fi

    # Docker logs
    if [ -d "/var/lib/docker/containers" ]; then
        find /var/lib/docker/containers -name "*.log" -type f -mtime +7 -delete
        log "Cleaned Docker logs (removed older than 7 days)"
    fi

    # Application logs
    if [ -d "./logs" ]; then
        find ./logs -name "*.log" -type f -mtime +30 -delete
        log "Cleaned application logs (removed older than 30 days)"
    fi
}

# Temporary file cleanup
cleanup_temp() {
    log "Cleaning up temporary files..."

    # System temp
    if [ -d "/tmp" ]; then
        find /tmp -type f -atime +7 -delete 2>/dev/null || true
        find /tmp -type d -empty -delete 2>/dev/null || true
        log "Cleaned /tmp (removed files older than 7 days)"
    fi

    # User temp
    if [ -d "$HOME/tmp" ] || [ -d "$HOME/temp" ]; then
        find "$HOME/tmp" "$HOME/temp" -type f -atime +7 -delete 2>/dev/null || true
        log "Cleaned user temp directories"
    fi
}

# Package cache cleanup
cleanup_cache() {
    log "Cleaning up package caches..."

    # APT cache (Debian/Ubuntu)
    if command -v apt-get &> /dev/null; then
        apt-get clean
        log "Cleaned APT cache"
    fi

    # YUM cache (RHEL/CentOS)
    if command -v yum &> /dev/null; then
        yum clean all
        log "Cleaned YUM cache"
    fi

    # Homebrew cache (macOS)
    if command -v brew &> /dev/null; then
        brew cleanup
        log "Cleaned Homebrew cache"
    fi
}

# Disk space report
disk_report() {
    log "Disk space usage:"
    df -h | grep -E '^/dev/' | awk '{printf "  %s: %s used (%s available)\n", $6, $5, $4}'
}

main() {
    log "Starting system cleanup..."

    cleanup_docker
    cleanup_logs
    cleanup_temp
    cleanup_cache

    disk_report

    log "Cleanup complete!"
}

main "$@"



