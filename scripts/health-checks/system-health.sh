#!/bin/bash

# Home Lab System Health Check Script
# This script performs comprehensive health checks on your home datacenter

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/var/log/homelab-health-check.log"
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

# Start health check
log "Starting Home Lab System Health Check"
echo "====================================="
echo "Home Lab Health Check - $TIMESTAMP"
echo "====================================="

# System Information
log "Gathering system information..."
echo "System Information:"
echo "-------------------"
uname -a
echo "Uptime: $(uptime)"
echo ""

# CPU Usage
log "Checking CPU usage..."
echo "CPU Usage:"
echo "----------"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo "Current CPU Usage: $CPU_USAGE%"

if (( $(echo "$CPU_USAGE > 85" | bc -l) )); then
    error "CPU usage is critically high: $CPU_USAGE%"
elif (( $(echo "$CPU_USAGE > 70" | bc -l) )); then
    warning "CPU usage is high: $CPU_USAGE%"
    else
    success "CPU usage is normal: $CPU_USAGE%"
    fi
echo ""

# Memory Usage
log "Checking memory usage..."
echo "Memory Usage:"
echo "-------------"
MEM_INFO=$(free -h | grep "^Mem:")
MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
MEM_FREE=$(echo $MEM_INFO | awk '{print $4}')
MEM_USAGE_PERCENT=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')

echo "Total Memory: $MEM_TOTAL"
echo "Used Memory: $MEM_USED"
echo "Free Memory: $MEM_FREE"
echo "Memory Usage: $MEM_USAGE_PERCENT%"

if [ $MEM_USAGE_PERCENT -gt 90 ]; then
    error "Memory usage is critically high: $MEM_USAGE_PERCENT%"
elif [ $MEM_USAGE_PERCENT -gt 80 ]; then
    warning "Memory usage is high: $MEM_USAGE_PERCENT%"
else
    success "Memory usage is normal: $MEM_USAGE_PERCENT%"
fi
echo ""

# Disk Usage
log "Checking disk usage..."
echo "Disk Usage:"
echo "-----------"
df -h | grep -E '^/dev/' | while read line; do
    DEVICE=$(echo $line | awk '{print $1}')
    MOUNT=$(echo $line | awk '{print $6}')
    USAGE=$(echo $line | awk '{print $5}' | sed 's/%//')

    echo "Device: $DEVICE (Mount: $MOUNT) - Usage: $USAGE%"

    if [ $USAGE -gt 95 ]; then
        error "Disk usage critically high on $MOUNT: $USAGE%"
    elif [ $USAGE -gt 85 ]; then
        warning "Disk usage high on $MOUNT: $USAGE%"
    else
        success "Disk usage normal on $MOUNT: $USAGE%"
    fi
done
echo ""

# Network Connectivity
log "Checking network connectivity..."
echo "Network Connectivity:"
echo "--------------------"

    # Check internet connectivity
if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    success "Internet connectivity: OK"
    else
    error "Internet connectivity: FAILED"
    fi

# Check DNS resolution
if nslookup google.com >/dev/null 2>&1; then
    success "DNS resolution: OK"
    else
    error "DNS resolution: FAILED"
fi

# Check local network
if ping -c 1 -W 2 192.168.1.1 >/dev/null 2>&1; then
    success "Local network connectivity: OK"
else
    warning "Local network connectivity: Check router/gateway"
fi
echo ""

# Docker Services
log "Checking Docker services..."
echo "Docker Services:"
echo "----------------"

if command -v docker >/dev/null 2>&1; then
    if docker ps >/dev/null 2>&1; then
        RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | wc -l)
        TOTAL_CONTAINERS=$(docker ps -a --format "{{.Names}}" | wc -l)

        echo "Running containers: $RUNNING_CONTAINERS"
        echo "Total containers: $TOTAL_CONTAINERS"

        if [ "$RUNNING_CONTAINERS" -eq "$TOTAL_CONTAINERS" ]; then
            success "All containers are running"
        else
            STOPPED_CONTAINERS=$((TOTAL_CONTAINERS - RUNNING_CONTAINERS))
            warning "$STOPPED_CONTAINERS containers are stopped"

            echo "Stopped containers:"
            docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}"
        fi

        # Check specific services
        SERVICES=("plex" "prometheus" "grafana" "sonarr" "radarr")
        for service in "${SERVICES[@]}"; do
            if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
                success "$service: RUNNING"
            else
                error "$service: NOT RUNNING"
        fi
    done
    else
        error "Cannot connect to Docker daemon"
    fi
else
    warning "Docker is not installed or not running"
fi
echo ""

# Plex Health Check
log "Checking Plex health..."
echo "Plex Health:"
echo "------------"

if curl -s --max-time 10 http://localhost:32400/web/index.html >/dev/null 2>&1; then
    success "Plex web interface: ACCESSIBLE"
else
    error "Plex web interface: NOT ACCESSIBLE"
fi
echo ""

# Temperature Check (if sensors available)
log "Checking system temperature..."
echo "System Temperature:"
echo "-------------------"

if command -v sensors >/dev/null 2>&1; then
    sensors | grep -E "(Core|CPU|temp)" | while read line; do
        TEMP=$(echo $line | grep -o '[0-9]\+\.[0-9]\+°C' | head -1 | sed 's/°C//')
        if [ ! -z "$TEMP" ]; then
            echo "$line"
            if (( $(echo "$TEMP > 80" | bc -l) )); then
                error "High temperature detected: $TEMP°C"
            elif (( $(echo "$TEMP > 70" | bc -l) )); then
                warning "Elevated temperature: $TEMP°C"
            else
                success "Temperature normal: $TEMP°C"
            fi
        fi
    done
else
    warning "Temperature sensors not available (install lm-sensors)"
fi
echo ""

# Backup Status
log "Checking backup status..."
echo "Backup Status:"
echo "--------------"

BACKUP_DIR="/path/to/backups"  # Update this path
if [ -d "$BACKUP_DIR" ]; then
    LAST_BACKUP=$(find "$BACKUP_DIR" -type f -name "*.tar.gz" -o -name "*.zip" | sort | tail -1)
    if [ ! -z "$LAST_BACKUP" ]; then
        LAST_BACKUP_DATE=$(stat -c %Y "$LAST_BACKUP" 2>/dev/null || stat -f %m "$LAST_BACKUP")
        DAYS_SINCE_BACKUP=$(( ( $(date +%s) - LAST_BACKUP_DATE ) / 86400 ))

        echo "Last backup: $(basename "$LAST_BACKUP")"
        echo "Days since last backup: $DAYS_SINCE_BACKUP"

        if [ $DAYS_SINCE_BACKUP -gt 7 ]; then
            error "Last backup is more than 7 days old"
        elif [ $DAYS_SINCE_BACKUP -gt 3 ]; then
            warning "Last backup is more than 3 days old"
        else
            success "Backup is recent"
        fi
    else
        error "No backup files found"
    fi
else
    warning "Backup directory not found: $BACKUP_DIR"
fi
echo ""

# Security Check
log "Performing basic security checks..."
echo "Security Checks:"
echo "----------------"

# Check for failed login attempts
if [ -f /var/log/auth.log ]; then
    FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
    echo "Failed login attempts (last 24h): $FAILED_LOGINS"

    if [ $FAILED_LOGINS -gt 10 ]; then
        warning "High number of failed login attempts: $FAILED_LOGINS"
    else
        success "Failed login attempts within normal range"
    fi
fi

# Check open ports
echo "Open ports:"
netstat -tlnp 2>/dev/null | grep LISTEN | awk '{print $4, $7}' | column -t
echo ""

# Summary
log "Health check completed"
echo "====================================="
echo "Health Check Summary - $TIMESTAMP"
echo "====================================="

# Count issues
ERRORS=$(grep -c "✗" "$LOG_FILE" 2>/dev/null || echo "0")
WARNINGS=$(grep -c "⚠" "$LOG_FILE" 2>/dev/null || echo "0")

if [ "$ERRORS" -gt 0 ]; then
    error "Found $ERRORS critical issues requiring immediate attention"
fi

if [ "$WARNINGS" -gt 0 ]; then
    warning "Found $WARNINGS warnings that should be reviewed"
fi

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    success "All systems appear to be healthy"
fi

echo ""
echo "Full log available at: $LOG_FILE"