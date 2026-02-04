#!/bin/bash

# Commands to run on your media server (mediaserver)
echo "🔍 Remote Radarr & Gluetun Diagnostic"
echo "====================================="
echo ""

echo "📦 Current Container Status:"
echo "----------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🌐 Gluetun VPN Details:"
echo "-----------------------"
echo "Gluetun Status:"
docker ps | grep gluetun

echo ""
echo "Gluetun Logs (last 20 lines):"
docker logs gluetun --tail 20

echo ""
echo "Gluetun VPN Connection Test:"
docker exec gluetun curl -s http://localhost:8000/v1/publicip/ip 2>/dev/null || echo "Cannot check VPN IP"

echo ""
echo "Gluetun Port Forwarding:"
docker exec gluetun curl -s http://localhost:8000/v1/openvpn/portforwarded 2>/dev/null || echo "Port forwarding info unavailable"

echo ""
echo "🔄 Radarr Status:"
echo "-----------------"
echo "Radarr Container:"
docker ps | grep radarr

echo ""
echo "Radarr Logs (last 20 lines):"
docker logs radarr --tail 20

echo ""
echo "🌐 Radarr Network Test:"
echo "-----------------------"
echo "Testing Radarr local access:"
curl -s -I http://localhost:7878 | head -1

echo ""
echo "Testing Radarr API:"
curl -s http://localhost:7878/api/v3/system/status | jq '.version' 2>/dev/null || echo "API not accessible or jq not installed"

echo ""
echo "📊 Network Connectivity:"
echo "------------------------"
echo "Ping test to gateway:"
ping -c 3 192.168.1.1 | tail -1

echo ""
echo "Internet connectivity:"
ping -c 3 8.8.8.8 | tail -1

echo ""
echo "🔍 Container Network Modes:"
echo "---------------------------"
echo "Radarr network mode:"
docker inspect radarr --format '{{.HostConfig.NetworkMode}}' 2>/dev/null || echo "Cannot check Radarr"

echo ""
echo "Gluetun network mode:"
docker inspect gluetun --format '{{.HostConfig.NetworkMode}}' 2>/dev/null || echo "Cannot check Gluetun"

