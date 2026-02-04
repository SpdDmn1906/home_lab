#!/bin/bash
echo "🔍 Plex Remote Access Diagnostic"
echo "================================"
echo ""

# Check Plex container
echo "1. Plex Container Status:"
docker ps | grep plex 2>/dev/null || echo "❌ Plex container not running"
echo ""

# Check port listening (if we can SSH)
echo "2. Port 32400 Status (requires SSH):"
echo "   Run on server: sudo netstat -tlnp | grep 32400"
echo ""

# Get public IP for testing
echo "3. Public IP (for external testing):"
curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Could not determine public IP"
echo ""

echo "📋 Next Steps:"
echo "- SSH into server (192.168.1.11) and run: docker ps | grep plex"
echo "- Check Plex Web UI: http://192.168.1.11:32400/web"
echo "- Verify Remote Access settings: Settings → Network → Remote Access"
echo "- Check router port forwarding: Port 32400 → 192.168.1.11"
