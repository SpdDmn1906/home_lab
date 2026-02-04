#!/bin/bash

echo "🔬 Detailed Eero Latency Analysis"
echo "=================================="
echo ""

echo "📊 Testing Environment:"
echo "Current network: $(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep -E "SSID|channel" | head -2)"
echo ""

# Function to test latency patterns
test_latency() {
    local target="$1"
    local test_name="$2"
    
    echo "🧪 Testing $test_name ($target):"
    echo "----------------------------------------"
    
    # Run ping test for 30 seconds to catch variations
    ping -t 30 "$target" 2>/dev/null | tail -n 20 | head -n 15
    
    echo ""
}

# Test Asus router (should be stable)
test_latency "192.168.1.1" "Asus Router Direct Connection"

# Test internet gateway (may show variations)
test_latency "8.8.8.8" "Internet Gateway (Google DNS)"

# Test local DNS resolution
echo "🧪 DNS Resolution Test:"
echo "----------------------------------------"
time nslookup google.com 2>/dev/null
echo ""

# Check WiFi interference
echo "📶 WiFi Environment Check:"
echo "----------------------------------------"
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s | head -10
echo ""

# Check ARP table for routing issues
echo "🔍 ARP Table (Network Routing):"
echo "----------------------------------------"
arp -a | grep -E "(192\.168\.1\.|eero)" | head -5
echo ""

echo "🎯 Analysis & Recommendations:"
echo "----------------------------------------"
echo ""
echo "🔴 HIGH LATENCY INDICATORS:"
echo "- Ping times >50ms consistently"
echo "- High standard deviation (>10ms)"
echo "- Packet loss >0%"
echo "- DNS resolution >1 second"
echo ""
echo "✅ GOOD PERFORMANCE INDICATORS:"
echo "- Ping times <20ms consistently"  
echo "- Low standard deviation (<5ms)"
echo "- 0% packet loss"
echo "- DNS resolution <0.1 seconds"
echo ""
echo "🔧 IMMEDIATE FIXES TO TRY:"
echo "1. Change Eero WiFi channels (avoid Asus channels)"
echo "2. Update all Eero firmware"
echo "3. Restart all Eero nodes"
echo "4. Disable/re-enable Eero WiFi temporarily"
echo "5. Test with device connected directly to Eero via Ethernet"
echo ""
echo "📊 If latency persists:"
echo "- Factory reset Eero and clean re-setup"
echo "- Consider disabling Eero WiFi and using Asus only"
echo "- Wired devices can still connect to Eero Ethernet ports"
echo ""
echo "📞 Run this script on BOTH networks:"
echo "- 'SC Home' (Asus) - should show excellent performance"
echo "- 'SC Home_Ext' (Eero) - shows the latency problem"
echo ""
echo "💡 KEY INSIGHT: Your Asus network works perfectly."
echo "   Eero latency is isolated - fixable without affecting main network!"

