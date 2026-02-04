#!/bin/bash
# Docker Backup Script
# Backs up Docker volumes and configurations

set -euo pipefail

# Configuration
BACKUP_ROOT="${BACKUP_ROOT:-./backups}"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/docker-backup-$DATE"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/volumes"
mkdir -p "$BACKUP_DIR/configs"

log "Starting Docker backup to $BACKUP_DIR"

# Backup docker-compose.yml
if [ -f "docker/docker-compose.yml" ]; then
    log "Backing up docker-compose.yml"
    cp docker/docker-compose.yml "$BACKUP_DIR/configs/"
fi

# Backup environment files
if [ -f ".env" ]; then
    log "Backing up .env file"
    cp .env "$BACKUP_DIR/configs/"
fi

# Backup monitoring configs
if [ -d "docker/monitoring" ]; then
    log "Backing up monitoring configurations"
    cp -r docker/monitoring "$BACKUP_DIR/configs/"
fi

# Backup Docker volumes
log "Backing up Docker volumes"
cd docker 2>/dev/null || cd . 2>/dev/null || true

if command -v docker-compose &> /dev/null; then
    VOLUMES=$(docker-compose config --volumes 2>/dev/null || echo "")
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    VOLUMES=$(docker compose config --volumes 2>/dev/null || echo "")
else
    warning "Docker Compose not found, skipping volume backup"
    VOLUMES=""
fi

for volume in $VOLUMES; do
    # Get the full volume name
    PROJECT_NAME="${COMPOSE_PROJECT_NAME:-homelab}"
    FULL_VOLUME_NAME="${PROJECT_NAME}_${volume}"

    # Check if volume exists
    if docker volume inspect "$FULL_VOLUME_NAME" &> /dev/null; then
        log "Backing up volume: $FULL_VOLUME_NAME"

        # Create backup using temporary container
        docker run --rm \
            -v "$FULL_VOLUME_NAME":/source:ro \
            -v "$BACKUP_DIR/volumes":/backup \
            alpine tar czf "/backup/${volume}.tar.gz" -C /source .

        log "Volume $volume backed up successfully"
    else
        warning "Volume $FULL_VOLUME_NAME not found, skipping"
    fi
done

# Create backup manifest
log "Creating backup manifest"
cat > "$BACKUP_DIR/manifest.txt" <<EOF
Docker Backup Manifest
Created: $(date)
Hostname: $(hostname)
Docker Version: $(docker --version)
Docker Compose Version: $(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null || echo "N/A")

Volumes Backed Up:
$(ls -1 "$BACKUP_DIR/volumes" 2>/dev/null | sed 's/^/  - /' || echo "  None")

Configurations Backed Up:
$(ls -1 "$BACKUP_DIR/configs" 2>/dev/null | sed 's/^/  - /' || echo "  None")
EOF

# Compress backup
log "Compressing backup"
cd "$BACKUP_ROOT"
tar czf "docker-backup-$DATE.tar.gz" "docker-backup-$DATE"
rm -rf "docker-backup-$DATE"
log "Backup compressed: docker-backup-$DATE.tar.gz"

# Calculate backup size
BACKUP_SIZE=$(du -h "docker-backup-$DATE.tar.gz" | cut -f1)
log "Backup size: $BACKUP_SIZE"

# Cleanup old backups
log "Cleaning up backups older than $RETENTION_DAYS days"
find "$BACKUP_ROOT" -name "docker-backup-*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
log "Cleanup complete"

log "Backup completed successfully!"
log "Backup location: $BACKUP_ROOT/docker-backup-$DATE.tar.gz"



