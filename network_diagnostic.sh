#!/bin/bash

echo "=== Home Lab Network Diagnostic ==="
echo "Testing connectivity between networks..."
echo ""

# Test from 10.0.0.0/8 network to 192.168.1.0/24 network
echo "Testing connectivity from 10.0.0.0/8 network:"
ping -c 3 192.168.1.1 2>/dev/null && echo "✓ Can reach Asus router" || echo "✗ Cannot reach Asus router"

# Test specific services
ping -c 3 192.168.1.11 2>/dev/null && echo "✓ Can reach media server (192.168.1.11)" || echo "✗ Cannot reach media server"

# Check current routing
echo ""
echo "Current routing table:"
ip route show | head -10

# Check DNS resolution
echo ""
echo "DNS test:"
nslookup google.com 2>/dev/null | head -3

echo ""
echo "=== Diagnostic Complete ==="
echo "If pings fail, networks are properly isolated (but this causes your issues!)"
