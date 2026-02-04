#!/bin/bash

echo "🔍 Home Lab Network Connectivity Test"
echo "====================================="
echo ""

# Get current network info
echo "📡 Current Network Configuration:"
echo "----------------------------------"

# Get IP address (works on both Linux and macOS)
if command -v ip >/dev/null 2>&1; then
    # Linux
    CURRENT_IP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $7}')
elif command -v ifconfig >/dev/null 2>&1; then
    # macOS or other BSD systems
    CURRENT_IP=$(ifconfig | grep -E 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
else
    CURRENT_IP="unknown"
fi

echo "Your IP: $CURRENT_IP"

if [[ $CURRENT_IP =~ ^10\. ]]; then
    echo "🌐 You're on the Xfinity/Eero network (10.0.0.0/8)"
    TARGET_NETWORK="192.168.1.0/24"
    TARGET_DESC="Asus network (media server/NAS)"
elif [[ $CURRENT_IP =~ ^192\.168\.1\. ]]; then
    echo "🏠 You're on the Asus network (192.168.1.0/24)"
    TARGET_NETWORK="10.0.0.0/8"
    TARGET_DESC="Xfinity/Eero network"
else
    echo "❓ You're on an unknown network"
    TARGET_NETWORK="unknown"
fi

echo ""
echo "🧪 Connectivity Tests:"
echo "----------------------"

if [ "$TARGET_NETWORK" != "unknown" ]; then
    # Test cross-network connectivity
    echo "Testing connectivity to $TARGET_DESC..."

    if [[ $TARGET_NETWORK == "192.168.1.0/24" ]]; then
        # From 10.x network, test Asus router
        ping -c 2 192.168.1.1 >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ Can reach Asus router (192.168.1.1)"
        else
            echo "❌ Cannot reach Asus router - networks are isolated"
        fi

        # Test media server (expected IP)
        ping -c 2 192.168.1.11 >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ Can reach media server (192.168.1.11)"
        else
            echo "❌ Cannot reach media server - this confirms the problem!"
        fi
    else
        # From Asus network, test Xfinity router
        ping -c 2 10.0.0.1 >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ Can reach Xfinity router (10.0.0.1)"
        else
            echo "❌ Cannot reach Xfinity router - networks are isolated"
        fi
    fi
fi

echo ""
echo "📊 Network Performance Test:"
echo "-----------------------------"

# Test internet speed (quick test)
echo "Testing internet connectivity..."
ping -c 2 8.8.8.8 >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Internet connectivity: OK"
else
    echo "❌ Internet connectivity: FAILED"
fi

echo ""
echo "🎯 Recommendations:"
echo "-------------------"
if [[ $CURRENT_IP =~ ^10\. ]] || [[ $CURRENT_IP =~ ^192\.168\.1\. ]]; then
    echo "Your dual-network setup is confirmed. Migration recommended!"
    echo "📖 Read: NETWORK_MIGRATION_PLAN.md"
else
    echo "Network configuration unclear. Check your setup."
fi

echo ""
echo "🔧 Next Steps:"
echo "- Run this script from devices on BOTH networks"
echo "- Document any connectivity failures"
echo "- Follow the migration plan to unify networks"
