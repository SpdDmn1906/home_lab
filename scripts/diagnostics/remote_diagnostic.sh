#!/bin/bash

echo "🔍 REMOTE DIAGNOSTIC: Gluetun & qBittorrent Mount Issues"
echo "======================================================"
echo ""

echo "📍 Server: $(hostname) ($(hostname -I | awk '{print $1}'))"
echo "👤 User: $(whoami)"
echo "📅 Date: $(date)"
echo ""

# Check containers
echo "📦 Container Status:"
echo "-------------------"
if docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -q gluetun; then
    echo "✅ Gluetun running:"
    docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep gluetun
else
    echo "❌ Gluetun NOT running"
fi

if docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -q qbittorrent; then
    echo "✅ qBittorrent running:"
    docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep qbittorrent
else
    echo "❌ qBittorrent NOT running"
fi
echo ""

# Check environment
echo "🌍 Environment Check:"
echo "----------------------"
if [ -f ".env" ]; then
    echo "✅ .env file exists:"
    cat .env | grep -E "(MEDIA_ROOT|EXTERNAL_MEDIA_ROOT|QBITTORRENT_CONFIG_PATH)" || echo "   No mount-related variables found"
else
    echo "❌ .env file NOT found"
fi
echo ""

# Check mount points
echo "💾 Mount Point Status:"
echo "----------------------"
MOUNT_CHECKS=(
    "/data/media:MEDIA_ROOT"
    "/external/media:EXTERNAL_MEDIA_ROOT" 
    "/home/youruser/Docker/qbittorrent:QBITTORRENT_CONFIG"
)

for check in "${MOUNT_CHECKS[@]}"; do
    PATH=$(echo $check | cut -d: -f1)
    LABEL=$(echo $check | cut -d: -f2)
    if [ -d "$PATH" ]; then
        SIZE=$(df -h "$PATH" 2>/dev/null | tail -1 | awk '{print $4}' || echo "unknown")
        echo "✅ $LABEL ($PATH): EXISTS (${SIZE} free)"
    else
        echo "❌ $LABEL ($PATH): MISSING"
    fi
done
echo ""

# Check Docker mounts
echo "🔗 Docker Mount Inspection:"
echo "----------------------------"
if docker ps | grep -q qbittorrent; then
    echo "qBittorrent container mounts:"
    docker inspect qbittorrent --format='{{range .Mounts}}{{.Source}}:{{.Destination}} ({{.Type}})
{{end}}' 2>/dev/null || echo "   Could not inspect mounts"
else
    echo "❌ qBittorrent container not running - cannot check mounts"
fi
echo ""

# Check NAS mount
echo "🖥️ NAS Mount Status:"
echo "--------------------"
if mount | grep -q "/external/media"; then
    echo "✅ NAS mounted:"
    mount | grep "/external/media"
else
    echo "❌ NAS NOT mounted at /external/media"
    echo "   Checking /etc/fstab for configuration:"
    if grep -q "192.168.1.20" /etc/fstab 2>/dev/null; then
        echo "   ✅ NAS entry found in fstab"
        cat /etc/fstab | grep "192.168.1.20"
    else
        echo "   ❌ No NAS entry in fstab"
    fi
fi
echo ""

# Check docker-compose.yml
echo "📝 Docker Compose Configuration:"
echo "---------------------------------"
if [ -f "docker-compose.yml" ]; then
    echo "✅ docker-compose.yml exists"
    echo "   qBittorrent volumes section:"
    grep -A 10 -B 2 "qbittorrent:" docker-compose.yml | grep -A 10 "volumes:" | head -15
else
    echo "❌ docker-compose.yml not found"
fi
echo ""

# Check qBittorrent settings
echo "⚙️ qBittorrent Settings Check:"
echo "------------------------------"
if docker ps | grep -q qbittorrent; then
    echo "Checking qBittorrent save path..."
    # Try to get settings via API (may require authentication)
    QB_SETTINGS=$(docker exec qbittorrent curl -s -u admin:admin http://localhost:8080/api/v2/app/preferences 2>/dev/null | jq -r '.save_path // empty' 2>/dev/null || echo "API_ACCESS_FAILED")
    
    if [ "$QB_SETTINGS" = "API_ACCESS_FAILED" ]; then
        echo "⚠️  Cannot access qBittorrent API (may need correct credentials)"
        echo "   Check WebUI at: http://192.168.1.11:8080"
        echo "   Default login: admin/admin"
    elif [ -n "$QB_SETTINGS" ]; then
        echo "✅ Current save path: $QB_SETTINGS"
        if [[ "$QB_SETTINGS" == "/downloads"* ]]; then
            echo "✅ Save path looks correct (container path)"
        else
            echo "⚠️  Save path may be incorrect: $QB_SETTINGS"
        fi
    else
        echo "⚠️  Could not retrieve save path"
    fi
else
    echo "❌ qBittorrent not running - cannot check settings"
fi
echo ""

# Recommendations
echo "💡 RECOMMENDATIONS:"
echo "==================="

ISSUES_FOUND=0

if ! docker ps | grep -q gluetun; then
    echo "❌ 1. Start Gluetun: docker-compose up -d gluetun"
    ((ISSUES_FOUND++))
fi

if ! docker ps | grep -q qbittorrent; then
    echo "❌ 2. Start qBittorrent: docker-compose up -d qbittorrent"
    ((ISSUES_FOUND++))
fi

if [ ! -f ".env" ]; then
    echo "❌ 3. Create .env file with proper mount paths"
    ((ISSUES_FOUND++))
fi

if [ ! -d "/external/media" ]; then
    echo "❌ 4. Mount NAS: sudo mount -t cifs //192.168.1.20/media /external/media -o username=guest,password=,vers=3.0"
    ((ISSUES_FOUND++))
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    echo "✅ All basic checks passed!"
    echo ""
    echo "If qBittorrent is still using wrong paths:"
    echo "   • Check qBittorrent WebUI settings (Tools → Preferences → Downloads)"
    echo "   • Verify NAS is properly mounted"
    echo "   • Check .env file has correct MEDIA_ROOT/EXTERNAL_MEDIA_ROOT paths"
else
    echo "❌ Found $ISSUES_FOUND issues to address"
fi
echo ""

echo "📋 QUICK FIX SUMMARY:"
echo "======================"
echo ""
echo "Run these commands to fix common issues:"
echo ""
echo "# 1. Check current status"
echo "docker ps | grep -E '(gluetun|qbittorrent)'"
echo ""
echo "# 2. Start containers if needed"
echo "docker-compose up -d"
echo ""
echo "# 3. Mount NAS if needed"
echo "sudo mkdir -p /external/media"
echo "sudo mount -t cifs //192.168.1.20/media /external/media -o username=guest,password=,vers=3.0"
echo ""
echo "# 4. Create .env file"
echo "cat > .env << EOF"
echo "MEDIA_ROOT=/data/media"
echo "EXTERNAL_MEDIA_ROOT=/external/media"
echo "QBITTORRENT_CONFIG_PATH=/home/youruser/Docker/qbittorrent"
echo "PUID=1000"
echo "PGID=1004"
echo "TZ=America/New_York"
echo "EOF"
echo ""
echo "# 5. Restart containers"
echo "docker-compose down && docker-compose up -d"
echo ""
echo "# 6. Check qBittorrent WebUI"
echo "echo 'Open: http://192.168.1.11:8080'"
echo "echo 'Default login: admin/admin'"

