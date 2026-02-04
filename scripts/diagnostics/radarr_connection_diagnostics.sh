#!/bin/bash

echo "🔍 Radarr Connection Diagnostic Tool"
echo "==================================="
echo ""

# Check if Radarr container is running
echo "📦 Radarr Container Status:"
echo "----------------------------"
RADARR_STATUS=$(docker ps | grep radarr | wc -l)
if [ "$RADARR_STATUS" -gt 0 ]; then
    echo "✅ Radarr container is RUNNING"
    RADARR_CONTAINER=$(docker ps | grep radarr | awk '{print $1}')
    echo "   Container ID: $RADARR_CONTAINER"
    
    # Check resource usage
    echo ""
    echo "📊 Container Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep radarr
    
    # Check network mode
    echo ""
    echo "🌐 Network Configuration:"
    NETWORK_MODE=$(docker inspect radarr --format '{{.HostConfig.NetworkMode}}')
    if echo "$NETWORK_MODE" | grep -q "service:gluetun"; then
        echo "✅ Connected to Gluetun VPN"
    else
        echo "❌ Not connected to VPN"
    fi
else
    echo "❌ Radarr container is NOT running"
    echo ""
    echo "🔧 Attempting to start Radarr:"
    START_RESULT=$(docker start radarr 2>/dev/null && echo "Started successfully" || echo "Failed to start")
    echo "   Result: $START_RESULT"
fi

# Check VPN status
echo ""
echo "🌐 VPN Status:"
echo "--------------"
VPN_STATUS=$(docker ps | grep gluetun | wc -l)
if [ "$VPN_STATUS" -gt 0 ]; then
    echo "✅ Gluetun VPN container is running"
    echo ""
    echo "🔗 VPN Connection Details:"
    docker exec gluetun curl -s http://localhost:8000/v1/publicip/ip 2>/dev/null || echo "   Unable to check VPN IP"
else
    echo "❌ Gluetun VPN container is NOT running - this will break Radarr!"
fi

echo ""
echo "📋 Radarr Logs (Last 20 lines):"
echo "================================"
docker logs radarr --tail 20 2>/dev/null || echo "❌ Cannot access Radarr logs"

echo ""
echo "🔍 Radarr Configuration Check:"
echo "==============================="

# Check if config directory exists
RADARR_CONFIG_PATH="/home/youruser/Docker/radarr"
if [ -d "$RADARR_CONFIG_PATH" ]; then
    echo "✅ Config directory exists: $RADARR_CONFIG_PATH"
    echo "   Config files:"
    ls -la "$RADARR_CONFIG_PATH" | grep -E "\.(xml|db|json)" | head -5
else
    echo "❌ Config directory missing: $RADARR_CONFIG_PATH"
fi

echo ""
echo "📁 Media Directory Check:"
echo "=========================="

# Check media directories
MEDIA_DIRS=("/data/media" "/data/media/Movies" "/data/media/downloads")
for dir in "${MEDIA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ Directory exists: $dir"
        echo "   Permissions: $(ls -ld "$dir" | awk '{print $1}')"
        echo "   Owner: $(ls -ld "$dir" | awk '{print $3}')"
    else
        echo "❌ Directory missing: $dir"
    fi
done

echo ""
echo "🌐 Network Connectivity Tests:"
echo "=============================="

# Test local connectivity
echo "Testing local network connectivity..."
ping -c 3 192.168.1.1 | tail -1

echo ""
echo "Testing internet connectivity..."
ping -c 3 8.8.8.8 | tail -1

echo ""
echo "🔧 Radarr Access Check:"
echo "========================"

# Test if Radarr web interface is accessible
RADARR_PORT=7878
if nc -z -w5 localhost $RADARR_PORT 2>/dev/null; then
    echo "✅ Radarr port $RADARR_PORT is accessible locally"
    
    # Test API endpoint
    API_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:$RADARR_PORT/api/v3/system/status" 2>/dev/null || echo "000")
    if [ "$API_RESPONSE" = "200" ]; then
        echo "✅ Radarr API is responding (HTTP $API_RESPONSE)"
    else
        echo "❌ Radarr API not responding (HTTP $API_RESPONSE)"
    fi
else
    echo "❌ Radarr port $RADARR_PORT is not accessible"
fi

echo ""
echo "🎯 DIAGNOSIS SUMMARY:"
echo "===================="

ISSUES_FOUND=0

if [ "$RADARR_STATUS" -eq 0 ]; then
    echo "❌ Radarr container not running"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

if [ "$VPN_STATUS" -eq 0 ]; then
    echo "❌ VPN not running - Radarr cannot connect to indexers"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

if ! nc -z -w5 localhost $RADARR_PORT 2>/dev/null; then
    echo "❌ Radarr web interface not accessible"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
fi

if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo "✅ Radarr appears to be running correctly"
    echo ""
    echo "💡 If web interface still not loading:"
    echo "   - Clear browser cache"
    echo "   - Try different browser"
    echo "   - Check firewall settings"
    echo "   - Verify correct URL: http://192.168.1.11:7878"
else
    echo "❌ Found $ISSUES_FOUND configuration issues"
fi

echo ""
echo "📋 RECOMMENDED FIXES:"
echo "====================="
echo ""
echo "1. 🔄 Restart All Services:"
echo "   docker-compose restart"
echo ""
echo "2. 🌐 Check VPN Connection:"
echo "   docker logs gluetun --tail 10"
echo ""
echo "3. 📊 Check Radarr Logs:"
echo "   docker logs radarr --tail 50"
echo ""
echo "4. 🔧 Verify Network Mode:"
echo "   docker inspect radarr | grep -A 5 NetworkMode"
echo ""
echo "5. 🌐 Test Access:"
echo "   curl http://localhost:7878"
echo ""
echo "6. 🚨 If still broken, check for port conflicts:"
echo "   netstat -tulpn | grep :7878"
echo ""
echo "7. 📁 Verify mount points:"
echo "   docker exec radarr ls -la /data"
echo ""

echo "💡 COMMON ISSUES:"
echo "================="
echo "- VPN not connected → Cannot reach indexers"
echo "- Port 7878 in use → Change port in config"
echo "- Config corruption → Check /config directory"
echo "- Network mode wrong → Must be 'service:gluetun'"
echo "- Permissions issue → Check file ownership"

