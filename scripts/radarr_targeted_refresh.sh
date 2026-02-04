#!/bin/bash
#
# Radarr Targeted Refresh & Search
# Only refreshes and searches for specific movie paths (not all missing movies)
#
# Usage: ./radarr_targeted_refresh.sh "/path/to/movie1" "/path/to/movie2" ...

set -e

# Get Radarr API key
API_KEY=$(docker exec radarr cat /config/config.xml 2>/dev/null | grep -oP '<ApiKey>\K[^<]+' || echo "")
if [ -z "$API_KEY" ]; then
    echo "❌ Could not find Radarr API key"
    exit 1
fi

RADARR_PORT=$(docker port radarr 2>/dev/null | grep "7878" | cut -d':' -f2 | head -1)
RADARR_PORT=${RADARR_PORT:-7878}
RADARR_URL="http://localhost:${RADARR_PORT}"

echo "🎬 Radarr Targeted Refresh & Search"
echo "   API: $RADARR_URL"
echo ""

if [ $# -eq 0 ]; then
    echo "❌ No movie paths provided"
    echo "Usage: $0 \"/path/to/movie1\" \"/path/to/movie2\" ..."
    exit 1
fi

# Get all movies from Radarr
echo "📋 Fetching movie library from Radarr..."
ALL_MOVIES=$(curl -s -H "X-Api-Key: $API_KEY" "$RADARR_URL/api/v3/movie")

MOVIE_IDS=()
MOVIE_TITLES=()

# Match provided paths to movie IDs
for movie_path in "$@"; do
    # Extract directory name (e.g., "Glory Road (2006)" from full path)
    movie_dir=$(basename "$(dirname "$movie_path")")

    # Try to find matching movie in Radarr by path or title
    movie_id=$(echo "$ALL_MOVIES" | jq -r --arg path "$movie_dir" \
        '.[] | select(.path | contains($path)) | .id' 2>/dev/null | head -1)

    if [ -n "$movie_id" ]; then
        title=$(echo "$ALL_MOVIES" | jq -r --arg id "$movie_id" \
            '.[] | select(.id == ($id | tonumber)) | "\(.title) (\(.year))"' 2>/dev/null)
        MOVIE_IDS+=("$movie_id")
        MOVIE_TITLES+=("$title")
        echo "  ✅ Found: $title (ID: $movie_id)"
    else
        echo "  ⚠️  Not found in Radarr: $movie_dir"
    fi
done

if [ ${#MOVIE_IDS[@]} -eq 0 ]; then
    echo ""
    echo "❌ No movies matched in Radarr"
    exit 1
fi

echo ""
echo "🔄 Refreshing ${#MOVIE_IDS[@]} specific movies..."

for i in "${!MOVIE_IDS[@]}"; do
    movie_id="${MOVIE_IDS[$i]}"
    title="${MOVIE_TITLES[$i]}"

    echo "  Refreshing: $title"

    # Refresh specific movie
    curl -s -X POST "$RADARR_URL/api/v3/command" \
        -H "X-Api-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"RefreshMovie\", \"movieIds\": [$movie_id]}" \
        >/dev/null 2>&1

    sleep 1
done

echo ""
echo "⏳ Waiting for refresh to complete (5s)..."
sleep 5

echo ""
echo "🔎 Triggering automatic search for these ${#MOVIE_IDS[@]} movies..."

for i in "${!MOVIE_IDS[@]}"; do
    movie_id="${MOVIE_IDS[$i]}"
    title="${MOVIE_TITLES[$i]}"

    echo "  Searching: $title"

    # Search for specific movie
    curl -s -X POST "$RADARR_URL/api/v3/command" \
        -H "X-Api-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"MoviesSearch\", \"movieIds\": [$movie_id]}" \
        >/dev/null 2>&1

    sleep 0.5
done

echo ""
echo "✅ Targeted refresh & search complete!"
echo ""
echo "💡 Monitor downloads: http://192.168.1.11:7878/queue"

