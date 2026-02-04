#!/bin/bash
API_KEY=$(grep -oP "(?<=<ApiKey>)[^<]+" /usr/local/bin/radarr/config/config.xml)
URL="http://localhost:7878/api/v3"

echo "Getting Quality Definitions..."
QUALITIES=$(curl -s "$URL/qualitydefinition" -H "X-Api-Key: $API_KEY")

# iterate through and update 1080p qualities
echo "$QUALITIES" | jq -c '.[]' | while read -r q; do
  ID=$(echo "$q" | jq '.id')
  NAME=$(echo "$q" | jq -r '.quality.name')
  
  if [[ "$NAME" == *"1080p"* ]]; then
    echo "Updating $NAME (ID: $ID)..."
    # Set max to 35 MB/min (~4GB for 120min)
    # Set preferred to 30 MB/min
    NEW_JSON=$(echo "$q" | jq '.maxSize = 35 | .preferredSize = 30')
    
    curl -s -X PUT "$URL/qualitydefinition/$ID"       -H "X-Api-Key: $API_KEY"       -H "Content-Type: application/json"       -d "$NEW_JSON" >/dev/null
    echo "Set $NAME to 35 MB/min."
  fi
done
