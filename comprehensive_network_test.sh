#!/bin/bash

echo "🔬 Comprehensive Home Lab Network Analysis"
echo "==========================================="
echo ""

# Get current network info
echo "📡 Current Device Network Status:"
echo "----------------------------------"

# Get IP address (works on both Linux and macOS)
if command -v ip >/dev/null 2>&1; then
    CURRENT_IP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $7}')
    GATEWAY=$(ip route show | grep default | awk '{print $3}')
elif command -v ifconfig >/dev/null 2>&1; then
    CURRENT_IP=$(ifconfig | grep -E 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
    GATEWAY=$(netstat -rn | grep default | head -1 | awk '{print $2}')
else
    CURRENT_IP="unknown"
    GATEWAY="unknown"
fi

echo "Your IP: $CURRENT_IP"
echo "Gateway: $GATEWAY"

if [[ $CURRENT_IP =~ ^10\. ]]; then
    echo "🌐 You're on the Xfinity/Eero network (10.0.0.0/8)"
    CURRENT_NETWORK="xfinity_eero"
elif [[ $CURRENT_IP =~ ^192\.168\.1\. ]]; then
    echo "🏠 You're on the Asus network (192.168.1.0/24)"
    CURRENT_NETWORK="asus"
else
    echo "❓ You're on an unknown network: $CURRENT_IP"
    CURRENT_NETWORK="unknown"
fi

echo ""
echo "🔍 Detailed Connectivity Tests:"
echo "-------------------------------"

# Test 1: Can we reach the routers?
echo "Testing router connectivity..."
ping -c 2 -W 2 10.0.0.1 >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Can reach Xfinity router (10.0.0.1)"
else
    echo "❌ Cannot reach Xfinity router (10.0.0.1)"
fi

ping -c 2 -W 2 192.168.1.1 >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Can reach Asus router (192.168.1.1)"
else
    echo "❌ Cannot reach Asus router (192.168.1.1)"
fi

echo ""
echo "🖥️  Testing critical services connectivity:"
echo "------------------------------------------"

# Test media server IPs (expected + common fallbacks)
MEDIA_IPS=("192.168.1.11" "192.168.1.100" "192.168.1.101" "192.168.1.102" "192.168.1.50" "192.168.1.200")
for ip in "${MEDIA_IPS[@]}"; do
    ping -c 1 -W 1 $ip >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Media server found at: $ip"
        break
    fi
done

# Test NAS IPs (expected + common fallbacks)
NAS_IPS=("192.168.1.20" "192.168.1.10" "192.168.1.100" "192.168.1.101")
for ip in "${NAS_IPS[@]}"; do
    ping -c 1 -W 1 $ip >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ NAS found at: $ip"
        break
    fi
done

echo ""
echo "📊 Network Routing Analysis:"
echo "----------------------------"

# Show routing table
echo "Routing table:"
if command -v ip >/dev/null 2>&1; then
    ip route show | grep -E "(default|192\.168\.1\.|10\.0\.0\.)" | head -5
elif command -v netstat >/dev/null 2>&1; then
    netstat -rn | grep -E "(default|192\.168\.1\.|10\.0\.0\.)" | head -5
fi

echo ""
echo "🔎 Cross-Network Test Results:"
echo "------------------------------"

if [ "$CURRENT_NETWORK" = "asus" ]; then
    echo "You are on the Asus network. Testing access to Xfinity/Eero devices..."

    # Test if we can reach Eero network devices
    ping -c 2 -W 2 10.0.0.10 >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Can reach devices on Xfinity/Eero network (10.0.0.x)"
        echo "   This suggests routing is working FROM Asus TO Xfinity"
    else
        echo "❌ Cannot reach devices on Xfinity/Eero network"
    fi

elif [ "$CURRENT_NETWORK" = "xfinity_eero" ]; then
    echo "You are on the Xfinity/Eero network. Testing access to Asus devices..."

    # Test if we can reach Asus network devices
    ping -c 2 -W 2 192.168.1.11 >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Can reach devices on Asus network (192.168.1.x)"
        echo "   This suggests routing is working FROM Xfinity TO Asus"
    else
        echo "❌ Cannot reach devices on Asus network"
        echo "   This confirms the network isolation issue!"
    fi
fi

echo ""
echo "🎯 Analysis & Recommendations:"
echo "------------------------------"

if [ "$CURRENT_NETWORK" = "asus" ]; then
    echo "📍 You are on the Asus network (where your media server lives)"
    echo "🔄 Run this script from a device on the Xfinity/Eero network (10.x.x.x)"
    echo "   to test if devices there can reach your media server"
    echo ""
    echo "If the Xfinity/Eero devices CANNOT reach Asus devices:"
    echo "→ Follow NETWORK_MIGRATION_PLAN.md to unify networks"
    echo ""
    echo "If they CAN reach Asus devices:"
    echo "→ The routing works one way. Check firewall rules on Asus router"

elif [ "$CURRENT_NETWORK" = "xfinity_eero" ]; then
    echo "📍 You are on the Xfinity/Eero network (where most devices are)"
    echo "🔄 Run this script from a device on the Asus network (192.168.1.x)"
    echo "   to test if the media server can reach Xfinity devices"
    echo ""
    echo "If Asus devices CANNOT reach Xfinity devices:"
    echo "→ Follow NETWORK_MIGRATION_PLAN.md to unify networks"
    echo ""
    echo "If they CAN reach Xfinity devices:"
    echo "→ Check firewall rules and port forwarding on routers"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Run this script on devices from BOTH networks"
echo "2. Note which direction connectivity fails"
echo "3. Follow the appropriate solution in NETWORK_MIGRATION_PLAN.md"
echo "4. Test Plex streaming after any network changes"

