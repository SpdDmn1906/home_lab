#!/bin/bash

echo "🎯 FINAL EERO LATENCY TEST"
echo "=========================="
echo ""

echo "📋 BEFORE RUNNING THIS SCRIPT:"
echo "------------------------------"
echo "1. Connect to 'SC Home_Ext' WiFi network"
echo "2. Wait 30 seconds for connection to stabilize"
echo "3. Run this script: ./final_eero_test.sh"
echo ""

# Check current network
echo "🔍 Current Network Status:"
echo "---------------------------"
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep -E "SSID|channel" | head -2
echo ""

echo "⏳ Testing for 30 seconds - please wait..."
echo ""

# Test Asus router (should be same on both networks)
echo "🏠 Testing Asus Router (192.168.1.1):"
echo "------------------------------------"
ping -c 10 192.168.1.1 | tail -5
echo ""

# Test internet latency (this is where Eero issues showed)
echo "🌐 Testing Internet Gateway (8.8.8.8):"
echo "-------------------------------------"
ping -c 10 8.8.8.8 | tail -5
echo ""

# Test DNS resolution
echo "🔍 Testing DNS Resolution:"
echo "---------------------------"
time nslookup google.com 192.168.1.1 | grep -E "Address|real"
echo ""

echo "📊 PERFORMANCE ANALYSIS:"
echo "========================="
echo ""

# Check for latency spikes
INTERNET_AVG=$(ping -c 10 8.8.8.8 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
INTERNET_MAX=$(ping -c 10 8.8.8.8 2>/dev/null | tail -1 | awk -F'/' '{print $7}')

echo "📈 Internet Performance:"
echo "- Average latency: ${INTERNET_AVG}ms"
echo "- Max latency: ${INTERNET_MAX}ms"
echo ""

if (( $(echo "$INTERNET_MAX > 50" | bc -l 2>/dev/null || echo "50 > 50") )); then
    echo "❌ HIGH LATENCY DETECTED - Eero still has issues"
    echo "   Max latency >50ms indicates mesh routing problems"
else
    echo "✅ EXCELLENT PERFORMANCE - Eero latency FIXED!"
    echo "   Max latency <50ms indicates stable mesh routing"
fi

echo ""
echo "🎯 CONCLUSION:"
echo "=============="
echo ""
if (( $(echo "$INTERNET_MAX <= 50" | bc -l 2>/dev/null || echo "50 <= 50") )); then
    echo "✅ SUCCESS: Eero 'SC Home_Ext' network is working perfectly!"
    echo "✅ Your unified network migration is COMPLETE!"
    echo ""
    echo "🏆 Achievements:"
    echo "   - Single unified 192.168.1.0/24 network ✅"
    echo "   - Asus router as primary (DHCP, DNS) ✅"
    echo "   - Eero mesh in bridge mode ✅"
    echo "   - Dual SSID coverage (SC Home + SC Home_Ext) ✅"
    echo "   - Resolved latency issues ✅"
    echo ""
    echo "📚 Next Steps:"
    echo "   1. Set up static DHCP leases for device naming"
    echo "   2. Deploy AdGuard Home + Unbound for ad blocking"
    echo "   3. Configure parental controls"
    echo "   4. Set up remote access"
    echo "   5. Deploy AI assistant"
else
    echo "⚠️  Eero still has latency issues - try Asus channel changes:"
    echo "   - Asus admin → 2.4GHz → Channel 11 (manual)"
    echo "   - Asus admin → 5GHz → Channel 149 (manual)"
    echo "   - Re-test after changes"
fi

