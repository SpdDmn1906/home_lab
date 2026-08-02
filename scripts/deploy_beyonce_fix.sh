#!/bin/bash
# Beyonce Renaissance - Automated Deployment Fix
# This script automates the Radarr profile creation and movie update.

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# API Configuration
RADARR_API_KEY="${RADARR_API_KEY:?Set RADARR_API_KEY in your shell environment or a local .env — never commit it}"
RADARR_URL="http://localhost:7878/api/v3"
PROWLARR_URL="http://localhost:9696/api/v1"

echo -e "${BLUE}=== Starting Beyonce Renaissance Deployment ===${NC}"

# 1. Get Prowlarr API Key
echo -e "1. Fetching Prowlarr API Key..."
P_KEY=$(docker exec prowlarr cat /config/config.xml 2>/dev/null | grep -oP "(?<=<ApiKey>)[^<]+" || echo "")
if [ -z "$P_KEY" ]; then
    echo -e "${RED}❌ Failed to find Prowlarr Key. Check if container is running.${NC}"
    exit 1
fi

# 2. Create the "Beyonce Rescue" Quality Profile in Radarr
echo -e "2. Creating 'Beyonce Rescue' Quality Profile in Radarr..."
# We fetch an existing profile to use as a template, then enable CAM/TS
TEMPLATE_PROFILE=$(curl -s "$RADARR_URL/qualityprofile?apikey=$RADARR_API_KEY" | jq '.[0]')
NEW_PROFILE=$(echo "$TEMPLATE_PROFILE" | jq '.name = "Beyonce Rescue" | .items = (.items | map(.allowed = (if .quality.name | test("CAM|TeleSync|HDCAM"; "i") then true else .allowed end)))')

# Check if profile already exists
EXISTING_ID=$(curl -s "$RADARR_URL/qualityprofile?apikey=$RADARR_API_KEY" | jq -r '.[] | select(.name == "Beyonce Rescue") | .id')

if [ -n "$EXISTING_ID" ] && [ "$EXISTING_ID" != "null" ]; then
    echo "   Profile already exists (ID: $EXISTING_ID). Skipping creation."
    PROFILE_ID=$EXISTING_ID
else
    PROFILE_ID=$(curl -s -X POST -H "Content-Type: application/json" -d "$NEW_PROFILE" "$RADARR_URL/qualityprofile?apikey=$RADARR_API_KEY" | jq -r '.id')
    echo -e "${GREEN}✅ Created 'Beyonce Rescue' Profile (ID: $PROFILE_ID).${NC}"
fi

# 3. Find the Movie and Update it
echo -e "3. Updating 'Renaissance' movie to use new profile..."
MOVIE_JSON=$(curl -s "$RADARR_URL/movie?apikey=$RADARR_API_KEY" | jq -r '.[] | select(.title | contains("Beyonce"))')

if [ -z "$MOVIE_JSON" ]; then
    echo -e "${RED}❌ Movie not found in Radarr. Please add it first.${NC}"
else
    MOVIE_ID=$(echo "$MOVIE_JSON" | jq -r '.id')
    UPDATED_MOVIE=$(echo "$MOVIE_JSON" | jq --arg pid "$PROFILE_ID" '.qualityProfileId = ($pid | tonumber) | .monitored = true')
    
    curl -s -X PUT -H "Content-Type: application/json" -d "$UPDATED_MOVIE" "$RADARR_URL/movie/$MOVIE_ID?apikey=$RADARR_API_KEY" > /dev/null
    echo -e "${GREEN}✅ Movie updated to 'Beyonce Rescue' profile and monitored.${NC}"

    # 4. Trigger Search
    echo -e "4. Triggering Search for the movie..."
    curl -s -X POST -H "Content-Type: application/json" -d "{\"name\": \"MoviesSearch\", \"movieIds\": [$MOVIE_ID]}" "$RADARR_URL/command?apikey=$RADARR_API_KEY" > /dev/null
    echo -e "${GREEN}✅ Search command issued. Check Radarr Activity!${NC}"
fi

echo ""
echo -e "${BLUE}=== Deployment Complete ===${NC}"
echo "Radarr is now searching for any available CAM/TS versions of the Beyonce film."
