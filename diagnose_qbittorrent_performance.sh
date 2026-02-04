#!/bin/bash

echo "🔍 qBittorrent Performance Diagnostic Tool"
echo "=========================================="
echo ""

MEDIA_SERVER="192.168.1.11"
SSH_USER="youruser"

echo "🎯 Target Server: $MEDIA_SERVER"
echo "📍 Running diagnostics remotely..."
echo ""

# Function to run commands on remote server
remote_exec() {
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$MEDIA_SERVER" "$1" 2>/dev/null
}

# Check if qBittorrent container is running
echo "📦 Checking qBittorrent Container Status:"
echo "------------------------------------------"
QB_STATUS=$(remote_exec "docker ps | grep qbittorrent" | wc -l)
if [ "$QB_STATUS" -gt 0 ]; then
    echo "✅ qBittorrent container is RUNNING"
    QB_CONTAINER=$(remote_exec "docker ps | grep qbittorrent | awk '{print \$1}'")
    echo "   Container ID: $QB_CONTAINER"

    # Check resource usage
    echo ""
    echo "📊 Container Resource Usage:"
    remote_exec "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}' | grep qbittorrent"

    # Check network mode
    echo ""
    echo "🌐 Network Configuration:"
    NETWORK_MODE=$(remote_exec "docker inspect qbittorrent --format '{{.HostConfig.NetworkMode}}'")
    if echo "$NETWORK_MODE" | grep -q "service:gluetun"; then
        echo "✅ Connected to Gluetun VPN"
    else
        echo "❌ Not connected to VPN"
    fi

    # Check VPN status
    VPN_STATUS=$(remote_exec "docker ps | grep gluetun" | wc -l)
    if [ "$VPN_STATUS" -gt 0 ]; then
        echo "✅ Gluetun VPN container is running"
        echo ""
        echo "🔗 VPN Connection Details:"
        remote_exec "docker exec gluetun curl -s http://localhost:8000/v1/openvpn/portforwarded 2>/dev/null" || echo "   Unable to check port forwarding"
    else
        echo "❌ Gluetun VPN container is NOT running"
    fi
else
    echo "❌ qBittorrent container is NOT running"
    echo ""
    echo "🔧 Attempting to start qBittorrent:"
    START_RESULT=$(remote_exec "docker start qbittorrent 2>/dev/null && echo 'Started' || echo 'Failed to start'")
    echo "   Result: $START_RESULT"
fi

echo ""
echo "🌐 Network Connectivity Tests:"
echo "-------------------------------"

# Test basic connectivity
echo "Testing local network connectivity..."
ping -c 3 192.168.1.1 | tail -1

echo ""
echo "Testing internet connectivity..."
ping -c 3 8.8.8.8 | tail -1

# Test VPN connectivity (if running)
if docker ps | grep -q gluetun; then
    echo ""
    echo "Testing VPN connectivity..."
    docker exec gluetun ping -c 3 8.8.8.8 2>/dev/null | tail -1 || echo "   VPN connectivity test failed"
fi

echo ""
echo "📡 Port Availability Check:"
echo "----------------------------"

# Check common torrent ports
echo "Checking common torrent ports (TCP):"
for port in 6881 6882 6883 6884 6885 6886 6887 6888 6889 6890; do
    if nc -z -w1 127.0.0.1 $port 2>/dev/null; then
        echo "   Port $port: ✅ OPEN"
    else
        echo "   Port $port: ❌ CLOSED"
    fi
done

echo ""
echo "⚙️ qBittorrent Configuration Check:"
echo "-----------------------------------"

# Check if config directory exists and is accessible
QB_CONFIG_PATH="/home/youruser/Docker/qbittorrent"
CONFIG_CHECK=$(remote_exec "[ -d '$QB_CONFIG_PATH' ] && echo 'EXISTS' || echo 'MISSING'")
if [ "$CONFIG_CHECK" = "EXISTS" ]; then
    echo "✅ Config directory exists: $QB_CONFIG_PATH"
    remote_exec "ls -la '$QB_CONFIG_PATH'" | head -5
else
    echo "❌ Config directory missing: $QB_CONFIG_PATH"
fi

echo ""
echo "💾 Download Directory Check:"
echo "-----------------------------"

# Check download directories
DOWNLOAD_DIRS=("/data/media/downloads" "/external/media/torrents")
for dir in "${DOWNLOAD_DIRS[@]}"; do
    DIR_CHECK=$(remote_exec "[ -d '$dir' ] && echo 'EXISTS' || echo 'MISSING'")
    if [ "$DIR_CHECK" = "EXISTS" ]; then
        echo "✅ Directory exists: $dir"
        remote_exec "df -h '$dir'" | tail -1
    else
        echo "❌ Directory missing: $dir"
    fi
done

echo ""
echo "🔧 qBittorrent Settings Recommendations:"
echo "---------------------------------------"

echo "If qBittorrent is slow, check these settings:"
echo ""
echo "1. 🌐 Connection Settings:"
echo "   - Protocol: Both TCP and μTP"
echo "   - Port: Use 6881-6889 (or let qBittorrent choose)"
echo "   - Alternative speed limits: 0 (unlimited)"
echo ""
echo "2. 🚀 Speed Settings:"
echo "   - Global max connections: 500"
echo "   - Max per torrent: 100"
echo "   - Global upload slots: 20"
echo "   - Max upload slots per torrent: 4"
echo ""
echo "3. 📁 Queue Settings:"
echo "   - Max active downloads: 5"
echo "   - Max active uploads: 10"
echo "   - Max active torrents: 20"
echo ""
echo "4. 🔒 Privacy Settings:"
echo "   - Enable encryption: Require encryption"
echo "   - Enable anonymous mode: OFF (may slow connections)"
echo ""
echo "5. 🌍 VPN-Specific Optimizations:"
echo "   - Use TCP instead of uTP (VPN compatibility)"
echo "   - Reduce max connections (VPN bandwidth limits)"
echo "   - Check VPN server load/location"

echo ""
echo "🧪 Quick Performance Tests:"
echo "---------------------------"

echo "Testing disk I/O performance on server..."
remote_exec "dd if=/dev/zero of=/tmp/testfile bs=1M count=50 2>&1 | tail -1 && rm -f /tmp/testfile"

echo ""
echo "Testing server network speed..."
remote_exec "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 - --simple 2>/dev/null | head -3" || echo "Speed test unavailable on server"

echo ""
echo "🎯 DIAGNOSIS SUMMARY:"
echo "===================="

# Analyze findings
ISSUES_FOUND=0

QB_RUNNING=$(remote_exec "docker ps | grep qbittorrent" | wc -l)
if [ "$QB_RUNNING" -eq 0 ]; then
    echo "❌ qBittorrent container not running"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

VPN_RUNNING=$(remote_exec "docker ps | grep gluetun" | wc -l)
if [ "$VPN_RUNNING" -eq 0 ]; then
    echo "❌ VPN not running - qBittorrent won't work"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo "✅ Basic setup appears correct"
    echo ""
    echo "💡 If downloads are still slow:"
    echo "   1. Check qBittorrent WebUI settings"
    echo "   2. Test with VPN disabled temporarily"
    echo "   3. Check torrent health (seeds/peers)"
    echo "   4. Verify ISP isn't throttling ports"
    echo "   5. Try different VPN server location"
else
    echo "❌ Found $ISSUES_FOUND configuration issues"
fi

echo ""
echo "📋 Next Steps:"
echo "=============="
echo "1. Review qBittorrent logs: docker logs qbittorrent"
echo "2. Check WebUI: http://192.168.1.11:8080"
echo "3. Test small torrent to isolate issue"
echo "4. Monitor VPN connection stability"

