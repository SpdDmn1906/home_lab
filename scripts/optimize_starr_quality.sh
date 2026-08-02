#!/bin/bash
set -e

R_KEY="${R_KEY:?Set R_KEY (Radarr API key) in your shell environment or a local .env — never commit it}"
S_KEY="${S_KEY:?Set S_KEY (Sonarr API key) in your shell environment or a local .env — never commit it}"

echo "=== Optimizing Radarr Quality Limits ==="
R_DEFS=$(curl -s "http://localhost:7878/api/v3/qualitydefinition?apikey=$R_KEY")

# Bluray-1080p -> 120 MB/min
NEW_R_DEFS=$(echo "$R_DEFS" | jq 'map(if .quality.name == "Bluray-1080p" then .maxSize = 120 else . end)')

# WEBDL-1080p -> 100 MB/min
NEW_R_DEFS=$(echo "$NEW_R_DEFS" | jq 'map(if .quality.name == "WEBDL-1080p" then .maxSize = 100 else . end)')

# PUT
curl -s -X PUT -H "Content-Type: application/json" -d "$NEW_R_DEFS" "http://localhost:7878/api/v3/qualitydefinition/update?apikey=$R_KEY" >/dev/null
echo "Radarr Updated."

echo "=== Optimizing Sonarr Quality Limits ==="
S_DEFS=$(curl -s "http://localhost:8989/api/v3/qualitydefinition?apikey=$S_KEY")

# Bluray-1080p -> 40 MB/min
NEW_S_DEFS=$(echo "$S_DEFS" | jq 'map(if .quality.name == "Bluray-1080p" then .maxSize = 40 else . end)')

# WEBDL-1080p -> 30 MB/min
NEW_S_DEFS=$(echo "$NEW_S_DEFS" | jq 'map(if .quality.name == "WEBDL-1080p" then .maxSize = 30 else . end)')

# PUT
curl -s -X PUT -H "Content-Type: application/json" -d "$NEW_S_DEFS" "http://localhost:8989/api/v3/qualitydefinition/update?apikey=$S_KEY" >/dev/null
echo "Sonarr Updated."
