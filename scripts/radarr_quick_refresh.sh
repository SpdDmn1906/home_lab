#!/bin/bash
#
# Quick Radarr Refresh Script
# Triggers both metadata refresh and disk scan via API
#
# Usage: ./radarr_quick_refresh.sh
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔄 RADARR QUICK REFRESH                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

SERVER_IP="192.168.1.11"
SERVER_USER="${SERVER_USER:?Set SERVER_USER in your shell environment or a local .env — never commit it}"
SERVER_PASS="${SERVER_PASS:?Set SERVER_PASS in your shell environment or a local .env — never commit it}"

# Execute on remote server
sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP 'bash -s' << 'EOFREMOTE'
#!/bin/bash

# Get Radarr API key
RADARR_KEY=$(docker exec radarr cat /config/config.xml 2>/dev/null | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')

if [ -z "$RADARR_KEY" ]; then
    echo "❌ Could not get Radarr API key"
    exit 1
fi

echo "🔄 Triggering Radarr Refresh & Scan..."
echo ""

# 1. Refresh Movie Metadata
echo "1. RefreshMovie (update metadata from APIs)..."
refresh_result=$(curl -s -X POST -H "X-Api-Key: $RADARR_KEY" \
    -H "Content-Type: application/json" \
    "http://localhost:7878/api/v3/command" \
    -d '{"name": "RefreshMovie"}')

refresh_id=$(echo "$refresh_result" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)

if [ -n "$refresh_id" ]; then
    echo "   ✅ Triggered (Command ID: $refresh_id)"
else
    echo "   ⚠️  Failed to trigger"
fi

echo ""

# 2. Rescan Disk
echo "2. RescanMovie (scan disk for file changes)..."
scan_result=$(curl -s -X POST -H "X-Api-Key: $RADARR_KEY" \
    -H "Content-Type: application/json" \
    "http://localhost:7878/api/v3/command" \
    -d '{"name": "RescanMovie"}')

scan_id=$(echo "$scan_result" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)

if [ -n "$scan_id" ]; then
    echo "   ✅ Triggered (Command ID: $scan_id)"
else
    echo "   ⚠️  Failed to trigger"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏱️  Operations Started"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "These operations typically take 3-5 minutes to complete."
echo ""
echo "Monitor progress:"
echo "  • Web UI: http://192.168.1.11:7878/system/tasks"
echo "  • Terminal: Watch the queue and missing count"
echo ""
echo "Waiting 3 minutes before checking status..."

sleep 180

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Status Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check command status
echo "Command Status:"
curl -s -H "X-Api-Key: $RADARR_KEY" "http://localhost:7878/api/v3/command" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for cmd in data[:5]:
        name = cmd.get('name', 'Unknown')
        status = cmd.get('status', 'Unknown')
        if 'Refresh' in name or 'Rescan' in name or 'Movie' in name:
            icon = '✅' if status == 'completed' else '⏳' if status in ['queued', 'started'] else '❌'
            print(f'  {icon} {name}: {status}')
except:
    print('  (Could not parse)')
"

echo ""

# Check missing count
missing=$(curl -s -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/wanted/missing?pageSize=1" | \
    python3 -c "import sys, json; print(json.load(sys.stdin).get('totalRecords', 'unknown'))" 2>/dev/null)

echo "Missing Movies: $missing"

# Check queue
queue=$(curl -s -H "X-Api-Key: $RADARR_KEY" \
    "http://localhost:7878/api/v3/queue" | \
    python3 -c "import sys, json; print(len(json.load(sys.stdin).get('records', [])))" 2>/dev/null)

echo "Download Queue: $queue"

echo ""
echo "✅ Refresh complete!"
echo ""
echo "If operations are still running, check again in a few minutes."

EOFREMOTE

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ REFRESH SCRIPT COMPLETE                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"

