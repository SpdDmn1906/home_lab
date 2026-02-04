#!/bin/bash

# Home Lab Maintenance Script
# Performs routine maintenance tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/var/log/homelab-maintenance.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Functions
log() {
    echo -e "${BLUE}[$TIMESTAMP]${NC} $1" | tee -a "$LOG_FILE"
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

# System updates
system_updates() {
    log "Checking for system updates..."

    if command -v apt >/dev/null 2>&1; then
        # Debian/Ubuntu
        apt update && apt upgrade -y && apt autoremove -y
        success "System updates completed (apt)"
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL
        yum update -y && yum autoremove -y
        success "System updates completed (yum)"
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora
        dnf update -y && dnf autoremove -y
        success "System updates completed (dnf)"
    else
        warning "Package manager not recognized - skipping system updates"
    fi
}

# Docker maintenance
docker_maintenance() {
    log "Performing Docker maintenance..."

    # Remove unused containers
    docker container prune -f

    # Remove unused images
    docker image prune -f

    # Remove unused networks
    docker network prune -f

    # Remove unused volumes
    docker volume prune -f

    success "Docker maintenance completed"
}

# Log rotation
log_rotation() {
    log "Rotating logs..."

    # Rotate system logs
    if command -v logrotate >/dev/null 2>&1; then
        logrotate /etc/logrotate.conf
        success "Log rotation completed"
    else
        warning "logrotate not available - skipping log rotation"
    fi

    # Clean old application logs
    find /var/log -name "*.log" -mtime +30 -delete 2>/dev/null || true
    find /var/log -name "*.gz" -mtime +90 -delete 2>/dev/null || true

    success "Old log cleanup completed"
}

# Disk cleanup
disk_cleanup() {
    log "Performing disk cleanup..."

    # Clean package cache
    if command -v apt >/dev/null 2>&1; then
        apt clean
    elif command -v yum >/dev/null 2>&1; then
        yum clean all
    elif command -v dnf >/dev/null 2>&1; then
        dnf clean all
    fi

    # Remove temporary files
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true

    # Clean user cache (be careful with this)
    # rm -rf ~/.cache/* 2>/dev/null || true

    success "Disk cleanup completed"
}

# Backup verification
backup_verification() {
    log "Verifying backups..."

    BACKUP_DIR="/path/to/backups"  # Update this path

    if [ -d "$BACKUP_DIR" ]; then
        # Check for recent backups
        RECENT_BACKUPS=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime -7 | wc -l)

        if [ "$RECENT_BACKUPS" -gt 0 ]; then
            success "Recent backups found: $RECENT_BACKUPS files"
        else
            warning "No recent backups found (last 7 days)"
        fi

        # Verify backup integrity (sample)
        LATEST_BACKUP=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        if [ ! -z "$LATEST_BACKUP" ]; then
            if tar -tzf "$LATEST_BACKUP" >/dev/null 2>&1; then
                success "Latest backup integrity verified"
            else
                error "Latest backup integrity check failed"
            fi
        fi
    else
        warning "Backup directory not found: $BACKUP_DIR"
    fi
}

# Security updates
security_updates() {
    log "Checking security updates..."

    if command -v unattended-upgrades >/dev/null 2>&1; then
        unattended-upgrades
        success "Security updates applied"
    else
        warning "unattended-upgrades not configured"
    fi
}

# Service restarts (if needed)
service_restarts() {
    log "Checking services that may need restart..."

    # Check if system was rebooted recently (indicating maintenance)
    UPTIME_SECONDS=$(awk '{print int($1)}' /proc/uptime)
    UPTIME_DAYS=$((UPTIME_SECONDS / 86400))

    if [ $UPTIME_DAYS -lt 1 ]; then
        warning "System recently rebooted - services should restart automatically"
    else
        # Check for services that may need restart after updates
        if command -v systemctl >/dev/null 2>&1; then
            # Check if any services failed
            FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
            if [ "$FAILED_SERVICES" -gt 0 ]; then
                warning "Found $FAILED_SERVICES failed services"
                systemctl --failed
            fi
        fi
    fi
}

# Health check
run_health_check() {
    log "Running health check..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    HEALTH_SCRIPT="$SCRIPT_DIR/../health-checks/system-health.sh"

    if [ -f "$HEALTH_SCRIPT" ]; then
        bash "$HEALTH_SCRIPT"
        success "Health check completed"
    else
        warning "Health check script not found: $HEALTH_SCRIPT"
    fi
}

# Main maintenance function
main() {
    log "Starting Home Lab Maintenance"
    echo "================================"
    echo "Home Lab Maintenance - $TIMESTAMP"
    echo "================================"

    # Run maintenance tasks
    system_updates
    echo ""

    docker_maintenance
    echo ""

    log_rotation
    echo ""

    disk_cleanup
    echo ""

    backup_verification
    echo ""

    security_updates
    echo ""

    service_restarts
    echo ""

    run_health_check
    echo ""

    log "Maintenance completed successfully"
    success "All maintenance tasks completed"

    echo ""
    echo "Maintenance logs available at: $LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    warning "Maintenance script not running as root - some operations may fail"
fi

# Run main function
main
