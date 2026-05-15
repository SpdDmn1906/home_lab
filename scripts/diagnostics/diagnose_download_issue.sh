#!/bin/bash

echo "🔍 Download Issue Diagnostic Tool"
echo "================================="
echo ""

echo "🎯 Problem: Nothing downloading in qBittorrent or Radarr"
echo ""

# Check container status
echo "📦 Container Status:"
echo "-------------------"
CONTAINERS=("gluetun" "qbittorrent" "radarr" "prowlarr")
for container in "${CONTAINERS[@]}"; do
    if docker ps | grep -q "$container"; then
        echo "✅ $container: RUNNING"
    else
        echo "❌ $container: NOT RUNNING"
    fi
done

echo ""
echo "🌐 Network Connectivity Test:"
echo "------------------------------"

# Test inter-container communication
echo "Testing Radarr → qBittorrent:"
if docker exec radarr curl -s --max-time 5 -u admin:admin http://qbittorrent:8080/api/v2/app/version 2>/dev/null; then
    echo "✅ Radarr can connect to qBittorrent"
else
    echo "❌ Radarr CANNOT connect to qBittorrent"
fi

echo ""
echo "Testing qBittorrent → Radarr:"
if docker exec qbittorrent curl -s --max-time 5 http://radarr:7878/api/v3/system/status 2>/dev/null; then
    echo "✅ qBittorrent can connect to Radarr"
else
    echo "❌ qBittorrent CANNOT connect to Radarr"
fi

echo ""
echo "🧲 qBittorrent Status:"
echo "----------------------"

# Check qBittorrent torrents
TORRENT_COUNT=$(docker exec qbittorrent curl -s -u admin:admin http://localhost:8080/api/v2/torrents/info 2>/dev/null | jq length 2>/dev/null || echo "0")
echo "Total torrents: $TORRENT_COUNT"

DOWNLOADING_COUNT=$(docker exec qbittorrent curl -s -u admin:admin http://localhost:8080/api/v2/torrents/info 2>/dev/null | jq '[.[] | select(.state == "downloading")] | length' 2>/dev/null || echo "0")
echo "Actively downloading: $DOWNLOADING_COUNT"

echo ""
echo "📊 Radarr Download Activity:"
echo "----------------------------"

# Check Radarr logs for download activity
DOWNLOAD_ACTIVITY=$(docker logs radarr --tail 50 2>/dev/null | grep -i "grabbed\|download" | wc -l)
echo "Recent download activity: $DOWNLOAD_ACTIVITY events"

echo ""
echo "🔧 Network Configuration:"
echo "------------------------"

# Check network modes
echo "Radarr network mode:"
docker inspect radarr 2>/dev/null | jq -r '.[0].HostConfig.NetworkMode' 2>/dev/null || echo "Cannot determine"

echo ""
echo "qBittorrent network mode:"
docker inspect qbittorrent 2>/dev/null | jq -r '.[0].HostConfig.NetworkMode' 2>/dev/null || echo "Cannot determine"

echo ""
echo "🎯 DIAGNOSIS:"
echo "============="

ISSUES_FOUND=0

if ! docker ps | grep -q gluetun; then
    echo "❌ VPN not running - cannot download"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

if ! docker exec radarr curl -s --max-time 5 -u admin:admin http://qbittorrent:8080/api/v2/app/version 2>/dev/null; then
    echo "❌ Inter-container communication broken"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

if [ "$DOWNLOADING_COUNT" = "0" ] && [ "$TORRENT_COUNT" -gt 0 ]; then
    echo "❌ Torrents exist but none downloading"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

if [ "$DOWNLOAD_ACTIVITY" = "0" ]; then
    echo "❌ No recent download activity in Radarr"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

if [ "$ISSUES_FOUND" = "0" ]; then
    echo "✅ No obvious issues detected"
else
    echo ""
    echo "❌ Found $ISSUES_FOUND issues requiring attention"
fi

echo ""
echo "💡 RECOMMENDED FIXES:"
echo "====================="
echo ""
echo "1. 🔄 Fix Inter-Container Communication:"
echo "   docker-compose down && docker-compose up -d"
echo ""
echo "2. 🌐 Verify Network Configuration:"
echo "   Both containers should use: network_mode: 'service:gluetun'"
echo ""
echo "3. 🔧 Check qBittorrent Settings:"
echo "   - Protocol: TCP (not uTP)"
echo "   - Connection limits reasonable for VPN"
echo "   - Authentication enabled"
echo ""
echo "4. 📊 Test Manual Download:"
echo "   Add a torrent directly to qBittorrent WebUI"
echo ""
echo "5. 🔍 Check Radarr Configuration:"
echo "   - Download client should point to: qbittorrent:8080"
echo "   - Username: admin, Password: (empty or default)"

