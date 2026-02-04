#!/bin/bash
# Update Docker Services Script
# Safely updates Docker images and restarts services

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

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if docker-compose.yml exists
COMPOSE_FILE="docker/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    error "docker-compose.yml not found at $COMPOSE_FILE"
    exit 1
fi

cd "$(dirname "$COMPOSE_FILE")" || exit 1

# Backup before updating
log "Creating backup before update..."
if [ -f "../scripts/backup/docker-backup.sh" ]; then
    bash "../scripts/backup/docker-backup.sh" || warning "Backup failed, continuing anyway"
fi

# Pull latest images
log "Pulling latest Docker images..."
docker-compose pull || docker compose pull

# Check for updates
log "Checking for image updates..."
UPDATED_IMAGES=$(docker-compose images -q | xargs docker images --format "{{.Repository}}:{{.Tag}}" || true)

if [ -z "$UPDATED_IMAGES" ]; then
    log "No updates available"
    exit 0
fi

# Ask for confirmation (non-interactive mode skips)
if [ "${1:-}" != "--yes" ]; then
    warning "The following images will be updated:"
    echo "$UPDATED_IMAGES"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Update cancelled"
        exit 0
    fi
fi

# Stop services gracefully
log "Stopping services..."
docker-compose down || docker compose down

# Remove old images (optional, saves space)
if [ "${2:-}" == "--prune" ]; then
    log "Removing old images..."
    docker image prune -f
fi

# Start services with new images
log "Starting services with updated images..."
docker-compose up -d || docker compose up -d

# Wait for services to be healthy
log "Waiting for services to start..."
sleep 10

# Check service status
log "Checking service status..."
docker-compose ps || docker compose ps

log "Update complete!"
log "Run 'docker-compose logs -f' to monitor service logs"



