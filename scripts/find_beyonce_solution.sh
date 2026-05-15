#!/bin/bash
# Beyonce Renaissance Solution Script
# Run this on your media server (192.168.1.11) to diagnose and fix the issue.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API Keys (from your config)
RADARR_API_KEY="***REMOVED***"
RADARR_URL="http://localhost:7878"
PROWLARR_URL="http://localhost:9696"

echo -e "${BLUE}=== Beyonce Renaissance Solution Diagnostic ===${NC}"
echo ""

# 1. Check Prowlarr API Key
echo -e "${BLUE}1. Checking Prowlarr API Key...${NC}"
PROWLARR_API_KEY=$(docker exec prowlarr cat /config/config.xml 2>/dev/null | grep -oP "(?<=<ApiKey>)[^<]+" || echo "")

if [ -z "$PROWLARR_API_KEY" ]; then
    echo -e "${RED}❌ Could not find Prowlarr API Key automatically.${NC}"
    echo "Please enter your Prowlarr API Key (Settings -> General):"
    read -r PROWLARR_API_KEY
else
    echo -e "${GREEN}✅ Found Prowlarr API Key.${NC}"
fi

# 2. Check Active Indexers
echo -e "${BLUE}2. Checking Prowlarr Indexers...${NC}"
INDEXERS=$(curl -s "$PROWLARR_URL/api/v1/indexer?apikey=$PROWLARR_API_KEY")
ACTIVE_INDEXERS=$(echo "$INDEXERS" | jq -r '.[] | select(.enable == true) | .name')

echo "Active Indexers:"
echo "$ACTIVE_INDEXERS"

REQUIRED_INDEXERS=("1337x" "TorrentGalaxy" "LimeTorrents")
MISSING_INDEXERS=()

for indexer in "${REQUIRED_INDEXERS[@]}"; do
    if echo "$ACTIVE_INDEXERS" | grep -iq "$indexer"; then
        echo -e "${GREEN}✅ $indexer is active.${NC}"
    else
        echo -e "${RED}❌ $indexer is MISSING!${NC}"
        MISSING_INDEXERS+=("$indexer")
    fi
done

if [ ${#MISSING_INDEXERS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Recommendation: Add missing indexers in Prowlarr for better results.${NC}"
fi

# 3. Check Radarr Movie Status
echo -e "${BLUE}3. Checking Radarr for 'Renaissance'...${NC}"
MOVIE=$(curl -s "$RADARR_URL/api/v3/movie?apikey=$RADARR_API_KEY" | jq -r '.[] | select(.title | contains("Beyonce"))')

if [ -z "$MOVIE" ]; then
    echo -e "${RED}❌ Movie not found in Radarr library!${NC}"
    echo "Please add 'Renaissance: A Film by Beyonce' to Radarr first."
else
    TITLE=$(echo "$MOVIE" | jq -r '.title')
    PROFILE_ID=$(echo "$MOVIE" | jq -r '.qualityProfileId')
    MONITORED=$(echo "$MOVIE" | jq -r '.monitored')
    
    echo -e "${GREEN}✅ Found: $TITLE${NC}"
    echo "   Monitored: $MONITORED"
    echo "   Profile ID: $PROFILE_ID"
    
    # Check Profile
    PROFILE=$(curl -s "$RADARR_URL/api/v3/qualityprofile/$PROFILE_ID?apikey=$RADARR_API_KEY")
    PROFILE_NAME=$(echo "$PROFILE" | jq -r '.name')
    ALLOWED_QUALITIES=$(echo "$PROFILE" | jq -r '.items[] | select(.allowed == true) | .quality.name')
    
    echo "   Profile Name: $PROFILE_NAME"
    
    if echo "$ALLOWED_QUALITIES" | grep -Eiq "CAM|TeleSync|HDCAM"; then
        echo -e "${GREEN}✅ Profile allows CAM/TeleSync qualities.${NC}"
    else
        echo -e "${RED}❌ Profile '$PROFILE_NAME' BLOCKS CAM/TeleSync releases!${NC}"
        echo -e "${YELLOW}⚠️  Since no digital release exists, you MUST allow CAM/TS to find this movie.${NC}"
    fi
fi

# 4. Perform Deep Search
echo -e "${BLUE}4. Performing Deep Search via Prowlarr...${NC}"
echo "Searching for 'Beyonce Renaissance' on all indexers..."
SEARCH_RESULTS=$(curl -s "$PROWLARR_URL/api/v1/search?apikey=$PROWLARR_API_KEY&query=Beyonce%20Renaissance")
COUNT=$(echo "$SEARCH_RESULTS" | jq length)

if [ "$COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No results found on ANY active indexer.${NC}"
else
    echo -e "${GREEN}✅ Found $COUNT results.${NC}"
    echo "Top results (filtering for likely matches):"
    
    # Filter and display relevant results
    echo "$SEARCH_RESULTS" | jq -r '.[] | select(.title | test("Beyonce|Renaissance"; "i")) | "[\(.indexer)] \(.title) - \(.size) bytes - \(.guid)"' | head -n 10
fi

echo ""
echo -e "${BLUE}=== SOLUTION PLAN ===${NC}"
echo "1. If indexers are missing, add them in Prowlarr."
echo "2. If Radarr profile blocks CAM/TS, edit the profile or create a new one."
echo "3. If results appear above, manually grab them via Prowlarr or force Radarr to search."
echo ""
