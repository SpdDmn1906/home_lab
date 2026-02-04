#!/bin/bash

echo "🚀 Quick qBittorrent Diagnostic"
echo "==============================="
echo ""

# Check containers
echo "📦 Container Status:"
docker ps | grep -E "(qbittorrent|gluetun)" || echo "❌ No containers running"

echo ""
echo "🌐 VPN Test:"
docker exec gluetun ping -c 3 8.8.8.8 2>/dev/null || echo "❌ VPN not working"

echo ""
echo "📊 qBittorrent Logs (last 5 lines):"
docker logs qbittorrent --tail 5 2>/dev/null || echo "❌ Cannot access logs"

echo ""
echo "🔧 Quick Fixes:"
echo "1. Restart containers: docker-compose restart"
echo "2. Check qBittorrent WebUI: http://192.168.1.11:8080"
echo "3. Try different VPN server in docker-compose.yml"
echo "4. Test without VPN temporarily"
echo ""

