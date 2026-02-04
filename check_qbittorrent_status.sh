#!/bin/bash
# qBittorrent Status Check Script
# Run this on your media server (192.168.1.11) to diagnose download performance issues

echo "🔍 qBittorrent Status Check"
echo "============================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check container status
echo "📦 Container Status:"
echo "-------------------"
if docker ps --format '{{.Names}}' | grep -q '^qbittorrent$'; then
    echo -e "${GREEN}✅ qBittorrent container is RUNNING${NC}"
    docker ps --filter "name=qbittorrent" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Check if container is healthy
    HEALTH=$(docker inspect qbittorrent --format '{{.State.Health.Status}}' 2>/dev/null || echo "no-healthcheck")
    if [ "$HEALTH" = "healthy" ]; then
        echo -e "${GREEN}✅ Container health: HEALTHY${NC}"
    elif [ "$HEALTH" = "unhealthy" ]; then
        echo -e "${RED}❌ Container health: UNHEALTHY${NC}"
    else
        echo -e "${YELLOW}⚠️  Container health: $HEALTH${NC}"
    fi
else
    echo -e "${RED}❌ qBittorrent container is NOT running${NC}"
    echo "Checking if container exists but is stopped..."
    if docker ps -a --format '{{.Names}}' | grep -q '^qbittorrent$'; then
        echo "Container exists but is stopped. Status:"
        docker ps -a --filter "name=qbittorrent" --format "table {{.Names}}\t{{.Status}}"
    fi
    exit 1
fi

echo ""
echo "🔐 VPN (Gluetun) Status:"
echo "----------------------"
if docker ps --format '{{.Names}}' | grep -q '^gluetun$'; then
    echo -e "${GREEN}✅ Gluetun container is RUNNING${NC}"
    
    # Check VPN interface
    if docker exec gluetun ip addr show tun0 2>/dev/null | grep -q 'inet '; then
        VPN_IP=$(docker exec gluetun ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
        echo -e "${GREEN}✅ VPN interface (tun0) is UP${NC}"
        echo "   VPN IP: $VPN_IP"
    else
        echo -e "${RED}❌ VPN interface (tun0) is DOWN${NC}"
    fi
    
    # Check VPN connectivity
    echo ""
    echo "Testing VPN connectivity..."
    VPN_PUBLIC_IP=$(docker exec gluetun curl -s --max-time 5 http://ipinfo.io/ip 2>/dev/null || echo "FAILED")
    if [ "$VPN_PUBLIC_IP" != "FAILED" ] && [ -n "$VPN_PUBLIC_IP" ]; then
        echo -e "${GREEN}✅ VPN is connected${NC}"
        echo "   Public IP via VPN: $VPN_PUBLIC_IP"
    else
        echo -e "${RED}❌ VPN connectivity test FAILED${NC}"
    fi
    
    # Check Gluetun logs for errors
    echo ""
    echo "Recent Gluetun log entries (last 10 lines):"
    docker logs gluetun --tail 10 2>&1 | tail -5
else
    echo -e "${RED}❌ Gluetun container is NOT running${NC}"
    echo "qBittorrent requires Gluetun for VPN connectivity!"
fi

echo ""
echo "📊 qBittorrent Logs (Recent Errors/Warnings):"
echo "---------------------------------------------"
docker logs qbittorrent --tail 100 2>&1 | grep -iE '(error|warn|timeout|connection|failed|tracker|dht|peer)' | tail -20 || echo "No recent errors found in logs"

echo ""
echo "⚙️  Configuration Check:"
echo "----------------------"
QB_CONFIG_PATH="/usr/local/bin/qbittorrent/config"
if [ -d "$QB_CONFIG_PATH" ]; then
    echo -e "${GREEN}✅ Config directory exists: $QB_CONFIG_PATH${NC}"
    
    # Check if config file exists
    if [ -f "$QB_CONFIG_PATH/qBittorrent/qBittorrent.conf" ]; then
        echo -e "${GREEN}✅ Config file exists${NC}"
        
        # Check key optimization settings
        echo ""
        echo "Key Configuration Settings:"
        echo "---------------------------"
        
        MAX_CONN=$(grep "^Session\\MaxConnections=" "$QB_CONFIG_PATH/qBittorrent/qBittorrent.conf" 2>/dev/null | cut -d'=' -f2 || echo "not set")
        echo "Max Connections: $MAX_CONN"
        
        MAX_CONN_PER_TORRENT=$(grep "^Session\\MaxConnectionsPerTorrent=" "$QB_CONFIG_PATH/qBittorrent/qBittorrent.conf" 2>/dev/null | cut -d'=' -f2 || echo "not set")
        echo "Max Connections Per Torrent: $MAX_CONN_PER_TORRENT"
        
        DISK_CACHE=$(grep "^DiskCache\\Size=" "$QB_CONFIG_PATH/qBittorrent/qBittorrent.conf" 2>/dev/null | cut -d'=' -f2 || echo "not set")
        echo "Disk Cache Size (MB): $DISK_CACHE"
        
        UTP_ENABLED=$(grep "^Session\\EnableUTP=" "$QB_CONFIG_PATH/qBittorrent/qBittorrent.conf" 2>/dev/null | cut -d'=' -f2 || echo "not set")
        echo "uTP Enabled: $UTP_ENABLED"
        
        DHT_ENABLED=$(grep "^DHT\\Enabled=" "$QB_CONFIG_PATH/qBittorrent/qBittorrent.conf" 2>/dev/null | cut -d'=' -f2 || echo "not set")
        echo "DHT Enabled: $DHT_ENABLED"
        
        PEX_ENABLED=$(grep "^Session\\EnablePeerExchange=" "$QB_CONFIG_PATH/qBittorrent/qBittorrent.conf" 2>/dev/null | cut -d'=' -f2 || echo "not set")
        echo "Peer Exchange (PEX) Enabled: $PEX_ENABLED"
    else
        echo -e "${YELLOW}⚠️  Config file not found at expected location${NC}"
    fi
else
    echo -e "${RED}❌ Config directory missing: $QB_CONFIG_PATH${NC}"
fi

echo ""
echo "🌐 Network Connectivity Tests:"
echo "-----------------------------"

# Test DNS resolution
echo "Testing DNS resolution..."
if docker exec qbittorrent nslookup google.com 2>/dev/null | grep -q "Name:"; then
    echo -e "${GREEN}✅ DNS resolution working${NC}"
else
    echo -e "${RED}❌ DNS resolution FAILED${NC}"
fi

# Test tracker connectivity (common trackers)
echo ""
echo "Testing tracker connectivity..."
TRACKERS=("tracker.opentrackr.org:1337" "tracker.coppersurfer.tk:6969")
for tracker in "${TRACKERS[@]}"; do
    TRACKER_HOST=$(echo $tracker | cut -d':' -f1)
    if docker exec qbittorrent ping -c 1 -W 2 "$TRACKER_HOST" 2>/dev/null | grep -q "1 received"; then
        echo -e "${GREEN}✅ $tracker: Reachable${NC}"
    else
        echo -e "${YELLOW}⚠️  $tracker: Not reachable (may be normal)${NC}"
    fi
done

echo ""
echo "📈 Container Resource Usage:"
echo "---------------------------"
docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}' | grep -E "(CONTAINER|qbittorrent|gluetun)" || echo "Unable to get stats"

echo ""
echo "🔗 Network Mode Check:"
echo "--------------------"
NETWORK_MODE=$(docker inspect qbittorrent --format '{{.HostConfig.NetworkMode}}' 2>/dev/null)
echo "qBittorrent network mode: $NETWORK_MODE"
if [ "$NETWORK_MODE" = "container:gluetun" ]; then
    echo -e "${GREEN}✅ Correctly using Gluetun network${NC}"
else
    echo -e "${YELLOW}⚠️  Not using Gluetun network (expected: container:gluetun)${NC}"
fi

echo ""
echo "💡 Recommendations:"
echo "=================="
echo ""
echo "If downloads are slow, check:"
echo "1. VPN connection stability (check Gluetun logs)"
echo "2. Torrent health (seeds/peers ratio)"
echo "3. Disk I/O performance (check if disk is full or slow)"
echo "4. Network bandwidth (check if other services are using bandwidth)"
echo "5. qBittorrent settings (max connections, upload slots)"
echo ""
echo "To view qBittorrent WebUI: http://192.168.1.11:8080"
echo "To view detailed logs: docker logs -f qbittorrent"
echo "To restart qBittorrent: docker restart qbittorrent"
echo ""
