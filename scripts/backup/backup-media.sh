#!/bin/bash

# Home Lab Media and Configuration Backup Script
# This script creates automated backups of media files and configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Update these paths for your environment
BACKUP_ROOT="/path/to/backups"  # Main backup directory
MEDIA_SOURCE="/path/to/media"   # Media files directory
CONFIG_SOURCE="/path/to/config" # Configuration files directory
NAS_IP="192.168.1.20"          # NAS IP address
NAS_USER="admin"                # NAS username
RETENTION_DAYS=30               # How long to keep backups

# Timestamp
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
DATE=$(date '+%Y-%m-%d')

# Functions
log() {
    echo -e "${BLUE}[$TIMESTAMP]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# Create backup directories
create_backup_dirs() {
    log "Creating backup directories..."

    mkdir -p "$BACKUP_ROOT/daily"
    mkdir -p "$BACKUP_ROOT/weekly"
    mkdir -p "$BACKUP_ROOT/monthly"
    mkdir -p "$BACKUP_ROOT/logs"

    success "Backup directories created"
}

# Backup media files
backup_media() {
    log "Starting media backup..."

    BACKUP_FILE="$BACKUP_ROOT/daily/media_$TIMESTAMP.tar.gz"
    BACKUP_LOG="$BACKUP_ROOT/logs/media_backup_$TIMESTAMP.log"

    echo "Media backup started at $(date)" > "$BACKUP_LOG"

    # Calculate total size before backup
    TOTAL_SIZE=$(du -sh "$MEDIA_SOURCE" 2>/dev/null | awk '{print $1}' || echo "Unknown")
    echo "Total media size: $TOTAL_SIZE" >> "$BACKUP_LOG"

    # Create compressed archive
    if tar -czf "$BACKUP_FILE" -C "$(dirname "$MEDIA_SOURCE")" "$(basename "$MEDIA_SOURCE")" 2>>"$BACKUP_LOG"; then
        BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | awk '{print $1}')
        success "Media backup completed: $BACKUP_SIZE"

        echo "Backup completed at $(date)" >> "$BACKUP_LOG"
        echo "Backup file: $BACKUP_FILE" >> "$BACKUP_LOG"
        echo "Backup size: $BACKUP_SIZE" >> "$BACKUP_LOG"

        # Verify backup integrity
        if tar -tzf "$BACKUP_FILE" >/dev/null 2>&1; then
            success "Backup integrity verified"
        else
            error "Backup integrity check failed"
        fi
    else
        error "Media backup failed"
    fi
}

# Backup configurations
backup_configs() {
    log "Starting configuration backup..."

    BACKUP_FILE="$BACKUP_ROOT/daily/config_$TIMESTAMP.tar.gz"
    BACKUP_LOG="$BACKUP_ROOT/logs/config_backup_$TIMESTAMP.log"

    echo "Config backup started at $(date)" > "$BACKUP_LOG"

    # Create compressed archive of configurations
    if tar -czf "$BACKUP_FILE" \
        --exclude='*.log' \
        --exclude='*.tmp' \
        --exclude='cache' \
        -C "$(dirname "$CONFIG_SOURCE")" "$(basename "$CONFIG_SOURCE")" 2>>"$BACKUP_LOG"; then

        BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | awk '{print $1}')
        success "Configuration backup completed: $BACKUP_SIZE"

        echo "Backup completed at $(date)" >> "$BACKUP_LOG"
        echo "Backup file: $BACKUP_FILE" >> "$BACKUP_LOG"
        echo "Backup size: $BACKUP_SIZE" >> "$BACKUP_LOG"
    else
        error "Configuration backup failed"
    fi
}

# Sync to NAS (optional)
sync_to_nas() {
    log "Syncing backups to NAS..."

    if ping -c 1 -W 2 "$NAS_IP" >/dev/null 2>&1; then
        # Mount NAS share (adjust mount point and credentials as needed)
        MOUNT_POINT="/mnt/nas_backup"

        mkdir -p "$MOUNT_POINT"

        if mount -t cifs "//$NAS_IP/backup" "$MOUNT_POINT" -o username="$NAS_USER",password="$NAS_PASSWORD" 2>/dev/null; then
            # Sync backups to NAS
            rsync -avh --delete "$BACKUP_ROOT/daily/" "$MOUNT_POINT/daily/" >> "$BACKUP_ROOT/logs/nas_sync_$TIMESTAMP.log" 2>&1

            # Unmount
            umount "$MOUNT_POINT"

            success "Backup sync to NAS completed"
        else
            warning "Could not mount NAS share - skipping sync"
        fi
    else
        warning "NAS not reachable - skipping sync"
    fi
}

# Clean up old backups
cleanup_old_backups() {
    log "Cleaning up old backups..."

    # Remove backups older than retention period
    find "$BACKUP_ROOT/daily" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_ROOT/logs" -name "*.log" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Keep weekly backups for longer
    find "$BACKUP_ROOT/weekly" -name "*.tar.gz" -mtime +90 -delete 2>/dev/null || true

    # Keep monthly backups indefinitely (manual cleanup required)
    # find "$BACKUP_ROOT/monthly" -name "*.tar.gz" -mtime +365 -delete

    success "Old backup cleanup completed"
}

# Create weekly/monthly backups
create_periodic_backups() {
    DAY_OF_WEEK=$(date +%u)  # 1=Monday, 7=Sunday
    DAY_OF_MONTH=$(date +%d)

    # Weekly backup (every Sunday)
    if [ "$DAY_OF_WEEK" = "7" ]; then
        log "Creating weekly backup..."
        cp "$BACKUP_ROOT/daily/media_$TIMESTAMP.tar.gz" "$BACKUP_ROOT/weekly/media_weekly_$TIMESTAMP.tar.gz" 2>/dev/null || true
        cp "$BACKUP_ROOT/daily/config_$TIMESTAMP.tar.gz" "$BACKUP_ROOT/weekly/config_weekly_$TIMESTAMP.tar.gz" 2>/dev/null || true
        success "Weekly backup created"
    fi

    # Monthly backup (first day of month)
    if [ "$DAY_OF_MONTH" = "01" ]; then
        log "Creating monthly backup..."
        cp "$BACKUP_ROOT/daily/media_$TIMESTAMP.tar.gz" "$BACKUP_ROOT/monthly/media_monthly_$TIMESTAMP.tar.gz" 2>/dev/null || true
        cp "$BACKUP_ROOT/daily/config_$TIMESTAMP.tar.gz" "$BACKUP_ROOT/monthly/config_monthly_$TIMESTAMP.tar.gz" 2>/dev/null || true
        success "Monthly backup created"
    fi
}

# Send notification
send_notification() {
    log "Sending backup completion notification..."

    SUBJECT="Home Lab Backup Completed - $DATE"
    BODY="Backup completed successfully at $(date)

Daily backups created:
- Media: $(ls -lh $BACKUP_ROOT/daily/media_*.tar.gz 2>/dev/null | tail -1 | awk '{print $5}' || echo 'N/A')
- Config: $(ls -lh $BACKUP_ROOT/daily/config_*.tar.gz 2>/dev/null | tail -1 | awk '{print $5}' || echo 'N/A')

Total backup space used: $(du -sh $BACKUP_ROOT 2>/dev/null | awk '{print $1}' || echo 'Unknown')

Next cleanup will remove backups older than $RETENTION_DAYS days."

    # Email notification (requires mail command to be configured)
    if command -v mail >/dev/null 2>&1; then
        echo "$BODY" | mail -s "$SUBJECT" "$NOTIFICATION_EMAIL" 2>/dev/null || true
    fi

    success "Notification sent"
}

# Main backup process
main() {
    log "Starting Home Lab Backup Process"
    echo "=================================="
    echo "Home Lab Backup - $TIMESTAMP"
    echo "=================================="

    # Create backup directories
    create_backup_dirs

    # Perform backups
    backup_media
    backup_configs

    # Sync to NAS if configured
    sync_to_nas

    # Create periodic backups
    create_periodic_backups

    # Clean up old backups
    cleanup_old_backups

    # Send notification
    send_notification

    log "Backup process completed successfully"
    success "All backup operations completed"
}

# Check if running as root (recommended for backups)
if [ "$EUID" -ne 0 ]; then
    warning "Backup script not running as root - some operations may fail"
fi

# Run main function
main

echo ""
echo "Backup logs available in: $BACKUP_ROOT/logs/"
