#!/bin/bash
set -e

R_KEY="${R_KEY:?Set R_KEY (Radarr API key) in your shell environment or a local .env — never commit it}"

echo "=== Enforcing Strict 4GB Limit (Radarr) ==="
# Target: ~4GB for a 120min movie => ~34-35 MB/min
LIMIT=35

R_DEFS=$(curl -s "http://localhost:7878/api/v3/qualitydefinition?apikey=$R_KEY")

# Update 1080p qualities to 35 MB/min
NEW_R_DEFS=$(echo "$R_DEFS" | jq --argjson limit $LIMIT 'map(
  if .quality.name == "Bluray-1080p" or .quality.name == "WEBDL-1080p" or .quality.name == "HDTV-1080p" or .quality.name == "WEBRip-1080p" 
  then .maxSize = $limit 
  else . end
)')

# PUT
curl -s -X PUT -H "Content-Type: application/json" -d "$NEW_R_DEFS" "http://localhost:7878/api/v3/qualitydefinition/update?apikey=$R_KEY" >/dev/null
echo "Radarr 1080p Limits set to ${LIMIT} MB/min."
