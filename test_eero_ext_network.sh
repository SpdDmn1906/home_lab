#!/bin/bash

echo "🔬 Eero 'SC Home_Ext' Network Test"
echo "==================================="
echo ""

echo "📊 Current Network Status:"
echo "Current network: $(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep -E "SSID|channel" | head -2)"
echo "Current IP: $(ifconfig | grep -E 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')"
echo ""

echo "🧪 Testing Eero 'SC Home_Ext' Performance:"
echo "=========================================="

# Test Asus router through Eero mesh
echo "Testing Asus router via Eero mesh (192.168.1.1):"
ping -c 10 192.168.1.1 2>/dev/null | tail -1
echo ""

# Test internet gateway
echo "Testing internet gateway (8.8.8.8):"
ping -c 10 8.8.8.8 2>/dev/null | tail -1
echo ""

# Test DNS resolution
echo "Testing DNS resolution:"
time nslookup google.com 192.168.1.1 2>/dev/null | grep -A1 "Name:" | tail -1
echo ""

echo "🎯 Expected Results:"
echo "===================="
echo "✅ GOOD: Asus ping <15ms, internet <25ms, DNS <0.1s"
echo "⚠️  OK: Asus ping <25ms, internet <35ms, DNS <0.5s"
echo "🔴 BAD: Asus ping >25ms, internet >35ms, DNS >0.5s"
echo ""

echo "📊 COMPARISON WITH 'SC Home' NETWORK:"
echo "--------------------------------------"
echo "Previous 'SC Home' results:"
echo "- Asus router: 5-13ms range (excellent)"
echo "- Internet: 18-21ms (good)"
echo "- DNS: 0.051s (excellent)"
echo ""

echo "💡 If Eero 'SC Home_Ext' shows similar results:"
echo "- 🎉 SUCCESS: Network recreation fixed the issues!"
echo ""
echo "💡 If latency spikes persist:"
echo "- 🔄 Try: Reboot all Eero nodes in sequence"
echo "- 🔄 Try: Change Eero Thread channel (if possible)"
echo "- 🚨 Consider: Disable Eero WiFi, use Asus + wired satellites"

