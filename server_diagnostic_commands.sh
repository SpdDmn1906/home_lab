#!/bin/bash

echo "🖥️  SERVER DIAGNOSTIC COMMANDS"
echo "=============================="
echo ""
echo "Run these commands on your media server (mediaserver) to diagnose Gluetun and qBittorrent:"
echo ""

echo "1. 🔍 Check running containers:"
echo "   docker ps | grep -E '(gluetun|qbittorrent)'"
echo ""

echo "2. 🌍 Check environment variables:"
echo "   cat .env 2>/dev/null || echo '.env file not found'"
echo ""

echo "3. 💾 Check mount points exist:"
echo "   ls -la /data/media 2>/dev/null || echo '/data/media not found'"
echo "   ls -la /external/media 2>/dev/null || echo '/external/media not found'"
echo "   ls -la /home/youruser/Docker/qbittorrent 2>/dev/null || echo 'qbittorrent config not found'"
echo ""

echo "4. 🔗 Check Docker volume mounts:"
echo "   docker inspect qbittorrent --format='{{range .Mounts}}{{.Source}}:{{.Destination}} ({{.Type}}){{println}}{{end}}' 2>/dev/null || echo 'qbittorrent container not running'"
echo ""

echo "5. 📊 Check disk space:"
echo "   df -h | grep -E '(/$|/data|/external)'"
echo ""

echo "6. 🌐 Check network connectivity:"
echo "   ping -c 3 192.168.1.1"
echo "   curl -s http://192.168.1.1 | head -5"
echo ""

echo "7. ⚙️ Check qBittorrent settings:"
echo "   docker exec qbittorrent curl -s -u admin:admin http://localhost:8080/api/v2/app/preferences | jq '.save_path' 2>/dev/null || echo 'Cannot access qBittorrent API'"
echo ""

echo "8. 📝 Check current docker-compose.yml:"
echo "   cat docker-compose.yml | grep -A 10 -B 5 'qbittorrent:'"
echo ""

echo "9. 🔧 Quick fixes:"
echo "   # If containers not running:"
echo "   docker-compose up -d"
echo "   "
echo "   # If NAS not mounted:"
echo "   sudo mount -a  # Mount all fstab entries"
echo "   "
echo "   # Check qBittorrent WebUI:"
echo "   # Open browser to: http://192.168.1.11:8080"
echo "   # Default login: admin/admin"
echo ""

