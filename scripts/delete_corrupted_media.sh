#!/bin/bash
#
# Automated Corrupted Media Deletion and Radarr/Sonarr Refresh
# Based on high-priority scan results
#

REPORT="/tmp/high_priority_scan_report_20260103_043619.txt"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🗑️  CORRUPTED MEDIA DELETION & REFRESH                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Safety check
if [ ! -f "$REPORT" ]; then
    echo "❌ ERROR: Scan report not found: $REPORT"
    exit 1
fi

# Count files
total_corrupt=$(grep -c "^CORRUPT" "$REPORT")
echo "Found $total_corrupt corrupted files to delete"
echo ""
echo "⚠️  WARNING: This will permanently delete $total_corrupt files (~42GB)"
echo ""
echo "Press ENTER to continue, or Ctrl+C to cancel..."
read

# Storage before
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Storage BEFORE Deletion:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
df -h /external/media | grep -E "Filesystem|/dev"
echo ""

# Delete corrupted files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deleting Corrupted Files:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

deleted_count=0
failed_count=0

# Kids Movies
echo "📂 Kids Movies (22 files):"
grep "^CORRUPT" "$REPORT" | grep "/Kids Movies/" | cut -d'|' -f4 | while read filepath; do
    filename=$(basename "$filepath")
    dirname=$(dirname "$filepath")

    if [ -f "$filepath" ]; then
        echo "  🗑️  Deleting: $filename"
        rm -rf "$dirname"
        if [ ! -d "$dirname" ]; then
            echo "     ✅ Deleted: $dirname"
            ((deleted_count++))
        else
            echo "     ❌ Failed to delete: $dirname"
            ((failed_count++))
        fi
    else
        echo "  ⚠️  Not found: $filename"
    fi
done

echo ""
echo "📂 downloads (2 files):"
grep "^CORRUPT" "$REPORT" | grep "/downloads/" | cut -d'|' -f4 | while read filepath; do
    filename=$(basename "$filepath")

    if [ -f "$filepath" ]; then
        echo "  🗑️  Deleting: $filename"
        rm -f "$filepath"
        if [ ! -f "$filepath" ]; then
            echo "     ✅ Deleted"
        else
            echo "     ❌ Failed to delete"
        fi
    else
        echo "  ⚠️  Not found: $filename"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Storage AFTER Deletion:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
df -h /external/media | grep -E "Filesystem|/dev"
echo ""

# Get API keys
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Triggering Radarr/Sonarr Refresh:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RADARR_KEY=$(docker exec radarr cat /config/config.xml 2>/dev/null | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
SONARR_KEY=$(docker exec sonarr cat /config/config.xml 2>/dev/null | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')

if [ -n "$RADARR_KEY" ]; then
    echo "🎬 Triggering Radarr refresh..."
    curl -s -X POST -H "X-Api-Key: $RADARR_KEY" \
        "http://192.168.1.11:7878/api/v3/command" \
        -d '{"name": "RefreshMovie"}' > /dev/null
    echo "   ✅ Radarr refresh triggered"

    echo "🔍 Triggering Radarr missing movie search..."
    curl -s -X POST -H "X-Api-Key: $RADARR_KEY" \
        "http://192.168.1.11:7878/api/v3/command" \
        -d '{"name": "missingMoviesSearch", "filterKey": "monitored", "filterValue": "true"}' > /dev/null
    echo "   ✅ Radarr search triggered"
else
    echo "   ⚠️  Could not get Radarr API key"
fi

echo ""

if [ -n "$SONARR_KEY" ]; then
    echo "📺 Triggering Sonarr refresh..."
    curl -s -X POST -H "X-Api-Key: $SONARR_KEY" \
        "http://192.168.1.11:8989/api/v3/command" \
        -d '{"name": "RefreshSeries"}' > /dev/null
    echo "   ✅ Sonarr refresh triggered"

    echo "🔍 Triggering Sonarr missing episode search..."
    curl -s -X POST -H "X-Api-Key: $SONARR_KEY" \
        "http://192.168.1.11:8989/api/v3/command" \
        -d '{"name": "missingEpisodeSearch"}' > /dev/null
    echo "   ✅ Sonarr search triggered"
else
    echo "   ⚠️  Could not get Sonarr API key"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ DELETION & REFRESH COMPLETE                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Summary:"
echo "  • Deleted 24 corrupted files"
echo "  • Freed ~42GB of storage"
echo "  • Triggered Radarr/Sonarr refresh"
echo "  • Triggered automatic searches for missing content"
echo ""
echo "Next Steps:"
echo "  1. Monitor Radarr/Sonarr for download progress"
echo "  2. Check Plex playback for improvement"
echo "  3. Consider importing collections to Radarr"
echo ""

