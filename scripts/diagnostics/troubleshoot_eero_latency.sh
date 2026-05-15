#!/bin/bash

echo "🔍 Eero Latency Troubleshooting Script"
echo "======================================"
echo ""

# Check current network
CURRENT_IP=$(ip route get 8.8.8.8 2>/dev/null | awk 'NR==1 {print $7}' || hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")

echo "📡 Current Network Status:"
echo "Your IP: $CURRENT_IP"

if [[ $CURRENT_IP =~ ^192\.168\.1\. ]]; then
    echo "✅ Connected to Asus 'SC Home' network"
elif [[ $CURRENT_IP =~ ^10\. ]]; then
    echo "⚠️  Connected to Xfi/Eero 'SC Home_Ext' network"
    echo "   (This might be causing the latency you're experiencing)"
else
    echo "❓ Unknown network"
fi

echo ""
echo "🧪 Latency Tests:"
echo "-----------------"

# Ping test to Asus router
echo "Testing connection to Asus router (192.168.1.1):"
ping -c 3 192.168.1.1 2>/dev/null | tail -1 || echo "❌ Cannot reach Asus router"

# Ping test to internet
echo ""
echo "Testing internet latency:"
ping -c 3 8.8.8.8 2>/dev/null | tail -1 || echo "❌ Cannot reach internet"

# DNS test
echo ""
echo "Testing DNS resolution:"
time nslookup google.com 2>/dev/null | grep -E "(Address|Query time)" | tail -1 || echo "❌ DNS issue"

echo ""
echo "🎯 Recommendations:"
echo "-------------------"
echo "1. If you're on 'SC Home_Ext' and experiencing latency:"
echo "   → Switch to 'SC Home' network temporarily"
echo "   → Follow Eero troubleshooting steps below"
echo ""
echo "2. Test both networks:"
echo "   → Run this script on 'SC Home' (should be fast)"
echo "   → Run this script on 'SC Home_Ext' (shows the problem)"
echo ""
echo "3. Eero Fixes to Try:"
echo "   → Factory reset Eero and re-setup in bridge mode"
echo "   → Disable Eero DHCP completely"
echo "   → Change Eero WiFi channels (avoid Asus channels)"
echo "   → Update Eero firmware"
echo ""
echo "4. If issues persist:"
echo "   → Consider disabling Eero WiFi temporarily"
echo "   → Use only Asus 'SC Home' network"
echo "   → Re-enable Eero later with fresh setup"

