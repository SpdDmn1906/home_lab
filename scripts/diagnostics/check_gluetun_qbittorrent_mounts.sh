#!/bin/bash

echo "🔍 Gluetun & qBittorrent Container & Mount Diagnostic"
echo "===================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MEDIA_SERVER="192.168.1.11"
SSH_USER="youruser"

echo -e "${BLUE}🎯 Target Server:${NC} $MEDIA_SERVER"
echo ""

# Check if we can connect
echo -e "${BLUE}🔗 Testing SSH Connection:${NC}"
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "echo 'SSH OK'" 2>/dev/null; then
    echo -e "${GREEN}✅ SSH connection successful${NC}"
else
    echo -e "${RED}❌ SSH connection failed${NC}"
    echo "Cannot run remote diagnostics. Please check:"
    echo "  1. Server is running: ping $MEDIA_SERVER"
    echo "  2. SSH service is running on server"
    echo "  3. SSH keys are properly configured"
    exit 1
fi

echo ""

# Check containers
echo -e "${BLUE}📦 Checking Container Status:${NC}"
CONTAINER_STATUS=$(ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E '(gluetun|qbittorrent)'" 2>/dev/null)

if echo "$CONTAINER_STATUS" | grep -q "gluetun\|qbittorrent"; then
    echo -e "${GREEN}✅ Containers found:${NC}"
    echo "$CONTAINER_STATUS"
else
    echo -e "${RED}❌ No Gluetun or qBittorrent containers running${NC}"
fi

echo ""

# Check environment variables
echo -e "${BLUE}🌍 Checking Environment Variables:${NC}"
echo "Expected docker-compose.yml environment variables:"
echo ""

ENV_VARS=("MEDIA_ROOT" "EXTERNAL_MEDIA_ROOT" "QBITTORRENT_CONFIG_PATH" "PUID" "PGID" "TZ")

for var in "${ENV_VARS[@]}"; do
    VALUE=$(ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "grep -E '^${var}=' .env 2>/dev/null || echo '${var}=NOT_SET'" 2>/dev/null)
    if echo "$VALUE" | grep -q "NOT_SET"; then
        echo -e "${YELLOW}⚠️  ${var}: NOT SET (using defaults)${NC}"
    else
        echo -e "${GREEN}✅ ${var}:${NC} $VALUE"
    fi
done

echo ""

# Check mount points
echo -e "${BLUE}💾 Checking Mount Points:${NC}"
echo ""

MOUNT_CHECKS=(
    "/data/media:MEDIA_ROOT (/data/media)"
    "/external/media:EXTERNAL_MEDIA_ROOT (/external/media)"
    "/home/youruser/Docker/qbittorrent:QBITTORRENT_CONFIG_PATH (./qbittorrent)"
)

for mount in "${MOUNT_CHECKS[@]}"; do
    HOST_PATH=$(echo "$mount" | cut -d: -f1)
    VAR_NAME=$(echo "$mount" | cut -d: -f2)
    DEFAULT_PATH=$(echo "$mount" | cut -d: -f3)
    
    EXISTS=$(ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "[ -d '$HOST_PATH' ] && echo 'EXISTS' || echo 'MISSING'" 2>/dev/null)
    
    if [ "$EXISTS" = "EXISTS" ]; then
        SIZE=$(ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "df -h '$HOST_PATH' | tail -1 | awk '{print \$4}'" 2>/dev/null)
        echo -e "${GREEN}✅ ${VAR_NAME}${NC}: $HOST_PATH ($SIZE free)"
    else
        echo -e "${RED}❌ ${VAR_NAME}${NC}: $HOST_PATH MISSING"
        echo -e "${YELLOW}   Will default to: $DEFAULT_PATH${NC}"
    fi
done

echo ""

# Check qBittorrent configuration
echo -e "${BLUE}⚙️ qBittorrent Configuration Check:${NC}"
QB_CONFIG_DIR=$(ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "ls -la /home/youruser/Docker/qbittorrent 2>/dev/null | head -1" 2>/dev/null)

if [ -n "$QB_CONFIG_DIR" ]; then
    echo -e "${GREEN}✅ qBittorrent config directory exists:${NC}"
    ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "ls -la /home/youruser/Docker/qbittorrent" 2>/dev/null
else
    echo -e "${RED}❌ qBittorrent config directory missing${NC}"
fi

echo ""

# Check Docker volume mounts
echo -e "${BLUE}🔗 Checking Docker Volume Mounts:${NC}"

if ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "docker ps | grep -q qbittorrent" 2>/dev/null; then
    echo -e "${GREEN}qBittorrent container volume mounts:${NC}"
    ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "docker inspect qbittorrent --format='{{range .Mounts}}{{.Source}}:{{.Destination}} ({{.Type}}){{println}}{{end}}'" 2>/dev/null
    
    echo ""
    echo -e "${GREEN}qBittorrent container environment:${NC}"
    ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "docker exec qbittorrent env | grep -E '(MEDIA_ROOT|EXTERNAL_MEDIA_ROOT|QBITTORRENT_CONFIG_PATH)' 2>/dev/null || echo 'No environment variables set in container'" 2>/dev/null
else
    echo -e "${RED}❌ qBittorrent container not running - cannot check mounts${NC}"
fi

echo ""

# Check actual qBittorrent settings (if running)
echo -e "${BLUE}🎬 qBittorrent Current Settings:${NC}"

if ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "docker ps | grep -q qbittorrent" 2>/dev/null; then
    # Try to get qBittorrent settings via API
    API_TEST=$(ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "docker exec qbittorrent curl -s -u admin:admin http://localhost:8080/api/v2/app/preferences 2>/dev/null | grep -o '\"save_path\":\"[^\"]*\"' | head -1" 2>/dev/null)
    
    if [ -n "$API_TEST" ]; then
        echo -e "${GREEN}✅ qBittorrent API accessible${NC}"
        echo "Current save path: $API_TEST"
    else
        echo -e "${YELLOW}⚠️  Cannot access qBittorrent API (may need authentication or different credentials)${NC}"
        echo "Check WebUI at: http://192.168.1.11:8080 (admin/admin by default)"
    fi
else
    echo -e "${RED}❌ Cannot check qBittorrent settings - container not running${NC}"
fi

echo ""

# Recommendations
echo -e "${BLUE}💡 RECOMMENDATIONS:${NC}"
echo ""

ISSUES_FOUND=0

# Check if containers are running
if ! ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "docker ps | grep -q gluetun" 2>/dev/null; then
    echo -e "${RED}❌ Start Gluetun container: docker-compose up -d gluetun${NC}"
    ((ISSUES_FOUND++))
fi

if ! ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "docker ps | grep -q qbittorrent" 2>/dev/null; then
    echo -e "${RED}❌ Start qBittorrent container: docker-compose up -d qbittorrent${NC}"
    ((ISSUES_FOUND++))
fi

# Check mount points
if ! ssh -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "[ -d '/external/media' ]" 2>/dev/null; then
    echo -e "${RED}❌ Create NAS mount: sudo mkdir -p /external/media${NC}"
    echo -e "${RED}❌ Mount NAS: Update /etc/fstab with correct NAS mount${NC}"
    ((ISSUES_FOUND++))
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All basic checks passed!${NC}"
    echo "If qBittorrent is still using wrong paths, check:"
    echo "  1. qBittorrent WebUI settings (Tools → Preferences → Downloads)"
    echo "  2. Verify NAS is properly mounted"
    echo "  3. Check .env file has correct paths"
else
    echo -e "${YELLOW}⚠️  Found $ISSUES_FOUND issues to address${NC}"
fi

echo ""
echo -e "${BLUE}📋 QUICK FIXES:${NC}"
echo ""
echo "1. Check .env file:"
echo "   cat ~/.env"
echo ""
echo "2. Verify NAS mount:"
echo "   df -h | grep -i nas"
echo "   ls -la /external/media"
echo ""
echo "3. Restart containers:"
echo "   docker-compose down && docker-compose up -d"
echo ""
echo "4. Check qBittorrent WebUI:"
echo "   http://192.168.1.11:8080"

