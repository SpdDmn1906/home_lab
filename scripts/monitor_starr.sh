#!/bin/bash
# Monitor STARR Stack Connectivity
# Checks if dependent containers started BEFORE the VPN container.
# If so, restarts them to re-establish network stack connection.

VPN_CONTAINER="qbittorrentvpn"
DEPENDENTS=("radarr" "sonarr" "prowlarr" "flaresolverr")

# Check if VPN is running
VPN_STATE=$(docker inspect -f '{{.State.Running}}' $VPN_CONTAINER 2>/dev/null)
if [ "$VPN_STATE" != "true" ]; then
    echo "$(date): VPN container $VPN_CONTAINER is not running. Waiting for it to start."
    exit 0
fi

# Get VPN Start Time (seconds since epoch)
VPN_START_TIME=$(docker inspect -f '{{.State.StartedAt}}' $VPN_CONTAINER)
# Use date -d to parse ISO8601. Remove sub-seconds for compatibility if needed, but date usually handles it.
VPN_TIMESTAMP=$(date -d "$VPN_START_TIME" +%s)

for container in "${DEPENDENTS[@]}"; do
    # Check if container exists/running
    CONTAINER_STATE=$(docker inspect -f '{{.State.Running}}' $container 2>/dev/null)
    
    if [ "$CONTAINER_STATE" != "true" ]; then
        echo "$(date): $container is stopped or missing. Attempting to start..."
        docker start $container
    else
        # Check start time
        CONTAINER_START_TIME=$(docker inspect -f '{{.State.StartedAt}}' $container)
        CONTAINER_TIMESTAMP=$(date -d "$CONTAINER_START_TIME" +%s)
        
        # If container started BEFORE VPN, it has a broken network link
        if [ "$CONTAINER_TIMESTAMP" -lt "$VPN_TIMESTAMP" ]; then
            echo "$(date): $container started before VPN (Stale Network). Restarting..."
            docker restart $container
        fi
    fi
done
