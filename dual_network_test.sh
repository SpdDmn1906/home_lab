#!/bin/bash

echo "🔄 Dual Network Performance Comparison Test"
echo "==========================================="
echo ""

# Function to get current network info
get_network_info() {
    echo "📊 Current Network Status:"
    echo "-------------------------"
    SSID=$(networksetup -getairportnetwork en0 2>/dev/null | cut -d: -f2 | xargs)
    echo "WiFi Network: ${SSID:-Not Connected}"
    
    CHANNEL_INFO=$(system_profiler SPAirPortDataType | grep -A 5 "Current Network Information" | grep "Channel:" | head -1)
    echo "Channel Info: ${CHANNEL_INFO:-Unknown}"
    
    IP_INFO=$(ipconfig getifaddr en0 2>/dev/null)
    echo "IP Address: ${IP_INFO:-Not Available}"
    
    GATEWAY=$(netstat -rn | grep default | head -1 | awk '{print $2}')
    echo "Gateway: ${GATEWAY:-Not Available}"
    echo ""
}

# Function to run latency tests
run_latency_tests() {
    echo "🧪 Latency Test Results ($1):"
    echo "------------------------------"
    
    echo "Asus Router (192.168.1.1):"
    ping -c 10 192.168.1.1 | tail -1
    
    echo ""
    echo "Internet Gateway (8.8.8.8):"
    ping -c 10 8.8.8.8 | tail -1
    
    echo ""
    echo "DNS Resolution Time:"
    time nslookup google.com >/dev/null 2>&1
    echo ""
}

# Main test logic
echo "🎯 NETWORK IDENTIFICATION:"
echo "--------------------------"
echo "Please ensure you're connected to the correct network:"
echo "• 'SC Home' = Asus router (should show excellent performance)"
echo "• 'SC Home_Ext' = Eero mesh (where latency issues occur)"
echo ""

get_network_info

# Ask user to confirm network
echo "❓ Are you currently connected to:"
echo "   1) 'SC Home' (Asus) - should show GOOD performance"
echo "   2) 'SC Home_Ext' (Eero) - where latency issues occur"
echo ""
read -p "Enter 1 or 2, or press Enter to test current network: " NETWORK_CHOICE

case $NETWORK_CHOICE in
    1)
        echo "✅ Testing 'SC Home' (Asus) network..."
        run_latency_tests "SC Home - Asus"
        ;;
    2)
        echo "🧪 Testing 'SC Home_Ext' (Eero) network..."
        run_latency_tests "SC Home_Ext - Eero"
        ;;
    *)
        echo "🔍 Testing current network (unknown which)..."
        SSID=$(networksetup -getairportnetwork en0 2>/dev/null | cut -d: -f2 | xargs)
        run_latency_tests "$SSID"
        ;;
esac

echo ""
echo "📋 NEXT STEPS:"
echo "--------------"
echo "1. Test on 'SC Home' (Asus) - should show <15ms latency"
echo "2. Test on 'SC Home_Ext' (Eero) - will show latency spikes if issue persists"
echo "3. Compare results between networks"
echo ""
echo "💡 If both networks show good performance now:"
echo "   • Your Eero recreation may have fixed the issue!"
echo "   • Continue monitoring for 24-48 hours"
echo ""
echo "🚨 If 'SC Home_Ext' still shows high latency:"
echo "   • Consider disabling Eero WiFi and using wired satellites only"
echo "   • Asus 'SC Home' provides reliable coverage for wireless devices"

