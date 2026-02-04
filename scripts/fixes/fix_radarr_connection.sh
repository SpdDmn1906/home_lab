#!/bin/bash

echo "🔧 Radarr Connection Fix Script"
echo "==============================="
echo ""

echo "Step 1: Checking current status..."
echo "----------------------------------"

# Check if containers are running
echo "Container Status:"
docker ps | grep -E "(radarr|gluetun)" || echo "❌ No containers running"

echo ""
echo "Step 2: Restarting VPN (most common fix)..."
echo "--------------------------------------------"

# Restart VPN first
echo "Stopping all services..."
docker-compose down

echo "Starting VPN..."
docker-compose up -d gluetun

echo "Waiting 30 seconds for VPN to connect..."
sleep 30

echo "Starting Radarr..."
docker-compose up -d radarr

echo "Waiting 10 seconds for Radarr to start..."
sleep 10

echo ""
echo "Step 3: Verifying fixes..."
echo "--------------------------"

# Check status again
echo "New Container Status:"
docker ps | grep -E "(radarr|gluetun)" || echo "❌ Still not running"

echo ""
echo "Testing Radarr connectivity:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:7878 || echo "❌ Cannot connect to Radarr"

echo ""
echo "Recent Radarr logs:"
docker logs radarr --tail 5

echo ""
echo "Recent VPN logs:"
docker logs gluetun --tail 5

echo ""
echo "🎯 RESULT:"
echo "=========="

# Test final status
RADARR_RUNNING=$(docker ps | grep radarr | wc -l)
VPN_RUNNING=$(docker ps | grep gluetun | wc -l)
RADARR_ACCESSIBLE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7878 2>/dev/null || echo "000")

if [ "$VPN_RUNNING" -gt 0 ] && [ "$RADARR_RUNNING" -gt 0 ] && [ "$RADARR_ACCESSIBLE" = "200" ]; then
    echo "✅ SUCCESS: Radarr is now running and accessible!"
    echo "   🌐 Access at: http://192.168.1.11:7878"
elif [ "$VPN_RUNNING" -eq 0 ]; then
    echo "❌ FAILED: VPN is not running - this is the primary issue"
    echo "   💡 Try: docker-compose logs gluetun"
elif [ "$RADARR_RUNNING" -eq 0 ]; then
    echo "❌ FAILED: Radarr container failed to start"
    echo "   💡 Try: docker logs radarr"
else
    echo "⚠️ PARTIAL: Containers running but Radarr not accessible"
    echo "   💡 Check: docker logs radarr --tail 20"
fi

echo ""
echo "📋 If still not working, run the full diagnostic:"
echo "   ./radarr_connection_diagnostics.sh"

