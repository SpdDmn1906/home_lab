#!/bin/bash

echo "🔬 Advanced Network Diagnostics"
echo "==============================="
echo ""

# Get detailed network info
echo "📊 Network Configuration:"
echo "-------------------------"

# Cross-platform network detection (macOS + Linux)
if [[ "$(uname -s)" == "Darwin" ]]; then
    # Prefer Wi-Fi interface (en0) on macOS
    CURRENT_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "unknown")
    GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway/ {print $2}' | head -1)
    # DNS servers (prefer networksetup; scutil is verbose and sometimes yields empty results via grep/awk)
    DNS_SERVERS=$(
        networksetup -getdnsservers "Wi-Fi" 2>/dev/null \
          | grep -v "There aren't any DNS Servers set" \
          | paste -sd' ' - \
          | sed 's/[[:space:]]*$//' \
        || true
    )
    if [[ -z "$DNS_SERVERS" ]]; then
        DNS_SERVERS=$(scutil --dns 2>/dev/null | awk '/nameserver\\[[0-9]+\\]/{print $3}' | paste -sd' ' - | sed 's/[[:space:]]*$//')
    fi
else
    CURRENT_IP=$(ip route get 8.8.8.8 2>/dev/null | awk 'NR==1 {print $7}' || hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")
    GATEWAY=$(ip route show 2>/dev/null | grep default | awk '{print $3}' || echo "unknown")
    DNS_SERVERS=$(cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' | tr '\n' ' ' || echo "unknown")
fi

GATEWAY=${GATEWAY:-unknown}
DNS_SERVERS=${DNS_SERVERS:-unknown}

echo "Current IP: $CURRENT_IP"
echo "Gateway: $GATEWAY"
echo "DNS Servers: $DNS_SERVERS"

# WiFi info (macOS)
echo ""
echo "📶 WiFi Information:"
echo "--------------------"
WIFI_INFO=$(system_profiler SPAirPortDataType 2>/dev/null | grep -A 10 "Current Network Information" | head -15 || echo "WiFi info not available")
echo "$WIFI_INFO"

echo ""
echo "🧪 Detailed Latency Analysis:"
echo "------------------------------"

# Multiple ping tests to identify patterns
echo "Testing Asus router (192.168.1.1) - 10 pings:"
ping -c 10 192.168.1.1 2>/dev/null | tail -3 || echo "❌ Cannot reach Asus router"

echo ""
echo "Testing Xfinity modem (10.0.0.1):"
ping -c 5 10.0.0.1 2>/dev/null | tail -2 || echo "❌ Cannot reach Xfinity modem"

echo ""
echo "Testing internet gateway:"
ping -c 5 8.8.8.8 2>/dev/null | tail -2 || echo "❌ Cannot reach internet"

echo ""
echo "🔍 Routing Analysis:"
echo "--------------------"

# Show routing table
echo "Routing table:"
netstat -rn 2>/dev/null | grep -E "(default|192\.168\.1|10\.0\.0)" | head -5 || ip route show 2>/dev/null | head -5 || echo "Cannot get routing table"

echo ""
echo "DNS Resolution Test:"
echo "---------------------"
time nslookup google.com 2>/dev/null || echo "DNS resolution failed"

echo ""
echo "🎯 Diagnostic Results:"
echo "----------------------"

# Analyze results
#
# IMPORTANT:
# Your environment uses a unified 192.168.1.0/24 LAN with multiple SSIDs (e.g. SC Home + SC Home_Ext).
# IP address alone cannot reliably identify which SSID/AP you're on.
# Use the WiFi section above (Channel / Width / Security) to distinguish behavior.
#
if [[ $CURRENT_IP =~ ^192\.168\.1\. ]]; then
    echo "✅ Connected to unified LAN (192.168.1.0/24)"
    echo "ℹ️  SSID/AP selection cannot be inferred from IP; see WiFi section above."

    if ping -c 1 10.0.0.1 >/dev/null 2>&1; then
        echo "✅ Can reach Xfinity modem - upstream path reachable"
    else
        echo "❌ Cannot reach Xfinity modem - check upstream routing/bridge mode"
    fi
elif [[ $CURRENT_IP =~ ^10\. ]]; then
    echo "⚠️  Connected to 10.0.0.0/8 (legacy network)"
    echo "💡 In a unified setup, prefer the 192.168.1.0/24 LAN."
else
    echo "❓ Network status unclear"
fi

echo ""
echo "🚨 Action Items:"
echo "----------------"
echo "1. Note current WiFi Channel/Width/Security (above) and correlate to latency spikes"
echo "2. If on wide channels (80/160MHz) and seeing spikes: reduce to 40MHz and retest"
echo "3. Prefer high 5GHz channels (149-161) for stability when available"
echo "4. Check Asus admin panel for connected devices and ensure single DHCP server"
echo "5. Verify Eero app shows 'Bridge Mode' and no DHCP conflicts"

