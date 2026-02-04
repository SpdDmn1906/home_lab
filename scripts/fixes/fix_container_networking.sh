#!/bin/bash

echo "🔧 Fix Container Networking"
echo "==========================="
echo ""

echo "🎯 Problem: Radarr cannot communicate with qBittorrent"
echo "📋 Solution: Ensure both containers use gluetun network"
echo ""

# Stop containers
echo "1. Stopping containers..."
docker stop radarr qbittorrent prowlarr flaresolverr 2>/dev/null
echo "   ✅ Containers stopped"
echo ""

# Ensure gluetun is running first
echo "2. Ensuring gluetun VPN is running..."
if ! docker ps | grep -q gluetun; then
    echo "   Starting gluetun..."
    docker start gluetun
    echo "   Waiting for VPN connection..."
    sleep 15
else
    echo "   ✅ Gluetun already running"
fi

# Check gluetun status
echo ""
echo "3. Checking VPN status..."
if docker exec gluetun curl -s http://localhost:8000/v1/publicip/ip 2>/dev/null | grep -q "New York"; then
    echo "   ✅ VPN connected to New York"
else
    echo "   ⚠️  VPN status unclear"
fi

# Start containers in correct order
echo ""
echo "4. Starting containers in dependency order..."

echo "   Starting qBittorrent..."
docker start qbittorrent
sleep 3

echo "   Starting Radarr..."
docker start radarr
sleep 3

echo "   Starting other services..."
docker start prowlarr flaresolverr 2>/dev/null
sleep 2

# Verify networking
echo ""
echo "5. Testing container networking..."

# Test 1: Can radarr ping qbittorrent?
echo "   Testing hostname resolution..."
if docker exec radarr ping -c 1 -W 2 qbittorrent 2>/dev/null | grep -q "1 received"; then
    echo "   ✅ Hostname resolution works"
else
    echo "   ❌ Hostname resolution failed"
fi

# Test 2: Can radarr access qbittorrent API?
echo "   Testing API communication..."
if docker exec radarr curl -s --max-time 5 -u admin:admin http://qbittorrent:8080/api/v2/app/version 2>/dev/null | grep -q "v4"; then
    echo "   ✅ API communication works"
    SUCCESS=true
else
    echo "   ❌ API communication failed"
    SUCCESS=false
fi

echo ""
echo "6. Final verification..."
docker ps | grep -E "(radarr|qbittorrent)" | awk '{print "   " $NF ": " $7}'

echo ""
if [ "$SUCCESS" = true ]; then
    echo "🎉 SUCCESS: Container networking fixed!"
    echo "   Radarr should now be able to send downloads to qBittorrent"
    echo ""
    echo "🧪 Test it:"
    echo "   - Access Radarr: http://192.168.1.11:7878"
    echo "   - Search for a movie and try to download"
    echo "   - Check qBittorrent: http://192.168.1.11:8080"
else
    echo "❌ FAILED: Networking still broken"
    echo ""
    echo "🔧 Advanced troubleshooting needed:"
    echo "   - Check docker-compose.yml network configuration"
    echo "   - Verify network_mode: 'service:gluetun'"
    echo "   - Consider recreating containers with proper networking"
fi

