#!/bin/bash

echo "🏥 Radarr Health Check"
echo "======================"
echo ""

ISSUES_FOUND=0
WARNINGS=0

# Function to report issues
report_issue() {
    echo "❌ ISSUE: $1"
    ISSUES_FOUND=$((ISSUES_FOUND+1))
}

report_warning() {
    echo "⚠️  WARNING: $1"
    WARNINGS=$((WARNINGS+1))
}

report_success() {
    echo "✅ $1"
}

echo "🔍 Checking Radarr Health..."
echo ""

# 1. Container Status
echo "1. Container Status:"
RADARR_CONTAINER=$(docker ps -q -f name=radarr)
if [ -n "$RADARR_CONTAINER" ]; then
    report_success "Radarr container is running"
    
    # Check container health
    HEALTH=$(docker inspect $RADARR_CONTAINER --format '{{.State.Health.Status}}' 2>/dev/null)
    if [ "$HEALTH" = "healthy" ]; then
        report_success "Radarr container is healthy"
    elif [ "$HEALTH" = "unhealthy" ]; then
        report_issue "Radarr container is unhealthy"
    else
        echo "ℹ️  Health check not configured"
    fi
else
    report_issue "Radarr container is not running"
fi

# 2. VPN Status
echo ""
echo "2. VPN Status:"
GLUETUN_CONTAINER=$(docker ps -q -f name=gluetun)
if [ -n "$GLUETUN_CONTAINER" ]; then
    report_success "Gluetun VPN container is running"
else
    report_issue "Gluetun VPN container is not running - Radarr cannot connect to indexers"
fi

# 3. Network Configuration
echo ""
echo "3. Network Configuration:"
if [ -n "$RADARR_CONTAINER" ]; then
    NETWORK_MODE=$(docker inspect $RADARR_CONTAINER --format '{{.HostConfig.NetworkMode}}')
    if echo "$NETWORK_MODE" | grep -q "gluetun"; then
        report_success "Radarr is connected to VPN network"
    else
        report_issue "Radarr is not connected to VPN network"
    fi
else
    report_issue "Cannot check network mode - container not running"
fi

# 4. Port Accessibility
echo ""
echo "4. Port Accessibility:"
if nc -z -w3 localhost 7878 2>/dev/null; then
    report_success "Radarr port 7878 is accessible"
else
    report_issue "Radarr port 7878 is not accessible"
fi

# 5. Web Interface
echo ""
echo "5. Web Interface:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7878 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "302" ]; then
    report_success "Radarr web interface is responding (HTTP $HTTP_STATUS)"
else
    report_issue "Radarr web interface not responding (HTTP $HTTP_STATUS)"
fi

# 6. API Connectivity
echo ""
echo "6. API Connectivity:"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:7878/api/v3/system/status" 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    report_success "Radarr API is working"
else
    report_issue "Radarr API not responding (HTTP $API_STATUS)"
fi

# 7. Configuration Directory
echo ""
echo "7. Configuration:"
CONFIG_DIR="/home/youruser/Docker/radarr"
if [ -d "$CONFIG_DIR" ]; then
    report_success "Configuration directory exists"
    
    # Check permissions
    if [ -w "$CONFIG_DIR" ]; then
        report_success "Configuration directory is writable"
    else
        report_issue "Configuration directory is not writable"
    fi
    
    # Check config file
    if [ -f "$CONFIG_DIR/config.xml" ]; then
        report_success "Config file exists"
    else
        report_warning "Config file missing - Radarr will create default"
    fi
else
    report_issue "Configuration directory does not exist"
fi

# 8. Media Directories
echo ""
echo "8. Media Directories:"
MEDIA_DIRS=("/data/media" "/data/media/Movies" "/data/media/downloads")
for dir in "${MEDIA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        if [ -r "$dir" ] && [ -w "$dir" ]; then
            report_success "Directory $dir is accessible"
        else
            report_issue "Directory $dir has permission issues"
        fi
    else
        report_warning "Directory $dir does not exist"
    fi
done

# 9. Resource Usage
echo ""
echo "9. Resource Usage:"
if [ -n "$RADARR_CONTAINER" ]; then
    STATS=$(docker stats --no-stream --format "CPU: {{.CPUPerc}}, Memory: {{.MemUsage}}" $RADARR_CONTAINER 2>/dev/null)
    if [ -n "$STATS" ]; then
        echo "📊 $STATS"
        
        # Check for high usage
        CPU_PCT=$(echo "$STATS" | grep -oP 'CPU: \K[\d.]+')
        if (( $(echo "$CPU_PCT > 80" | bc -l 2>/dev/null || echo "0 > 80") )); then
            report_warning "High CPU usage detected"
        fi
    else
        echo "ℹ️  Cannot retrieve stats"
    fi
else
    report_issue "Cannot check resources - container not running"
fi

# 10. Recent Logs
echo ""
echo "10. Recent Activity:"
if [ -n "$RADARR_CONTAINER" ]; then
    LOG_ENTRIES=$(docker logs $RADARR_CONTAINER --tail 5 2>/dev/null | wc -l)
    if [ "$LOG_ENTRIES" -gt 0 ]; then
        echo "📝 Recent logs available"
        
        # Check for errors in recent logs
        ERROR_COUNT=$(docker logs $RADARR_CONTAINER --tail 20 2>/dev/null | grep -i error | wc -l)
        if [ "$ERROR_COUNT" -gt 0 ]; then
            report_warning "$ERROR_COUNT error(s) in recent logs"
        fi
    else
        report_warning "No recent logs available"
    fi
else
    report_issue "Cannot check logs - container not running"
fi

echo ""
echo "📊 SUMMARY:"
echo "==========="
echo "Issues Found: $ISSUES_FOUND"
echo "Warnings: $WARNINGS"

if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo ""
    echo "🎉 Radarr appears to be healthy!"
    echo "   🌐 Access at: http://192.168.1.11:7878"
else
    echo ""
    echo "🔧 Issues need attention. Run the fix script:"
    echo "   ./fix_radarr_connection.sh"
    echo ""
    echo "📋 Or check detailed diagnostics:"
    echo "   ./radarr_connection_diagnostics.sh"
fi

echo ""
echo "💡 Pro Tips:"
echo "- Radarr must be connected to VPN to access indexers"
echo "- Check logs with: docker logs radarr --tail 20"
echo "- Monitor resources with: docker stats radarr"

