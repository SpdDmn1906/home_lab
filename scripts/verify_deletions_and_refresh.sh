#!/bin/bash
# Post-Deletion Verification & Radarr/Sonarr Refresh Script
# Run this AFTER completing File Station deletions

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     ✅ POST-DELETION VERIFICATION & REFRESH SCRIPT            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
RADARR_URL="http://192.168.1.11:7878"
SONARR_URL="http://192.168.1.11:8989"
RADARR_API_KEY=$(grep "RADARR_API_KEY" /home/youruser/Docker/starr/config/mediaserver.env 2>/dev/null | cut -d'=' -f2)
SONARR_API_KEY=$(grep "SONARR_API_KEY" /home/youruser/Docker/starr/config/mediaserver.env 2>/dev/null | cut -d'=' -f2)

echo "═══════════════════════════════════════════════════════════════"
echo "1️⃣  VERIFYING DELETIONS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

deleted_count=0
still_exists=0

# Verify 4K movies deleted
echo "📽️  4K Movies (should be gone):"
for movie in "The Dark Knight (2008) [2160p]" "The Matrix Reloaded (2003) [2160p]" "Harry.Potter.Complete"; do
    if find /home/youruser/synology/Media/Movies -maxdepth 1 -type d -name "*$movie*" 2>/dev/null | grep -q .; then
        echo "  ❌ STILL EXISTS: $movie"
        ((still_exists++))
    else
        echo "  ✅ DELETED: $movie"
        ((deleted_count++))
    fi
done

# Verify poor quality kids movies deleted
echo ""
echo "👶 Poor Quality Kids Movies (should be gone):"
for movie in "Sonic the Hedgehog 3" "Plankton The Movie" "Mufasa"; do
    if find /home/youruser/synology/Media/Movies\ -\ Kids -maxdepth 1 -type d -name "*$movie*" 2>/dev/null | grep -q .; then
        echo "  ❌ STILL EXISTS: $movie"
        ((still_exists++))
    else
        echo "  ✅ DELETED: $movie"
        ((deleted_count++))
    fi
done

# Verify From series deleted
echo ""
echo "📺 TV Shows (should be gone):"
if [ -d "/home/youruser/synology/Media/TV Shows/From (2022)" ]; then
    echo "  ❌ STILL EXISTS: From (2022)"
    ((still_exists++))
else
    echo "  ✅ DELETED: From (2022)"
    ((deleted_count++))
fi

# Check storage
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "💾 STORAGE STATUS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

df -h | grep -E "Filesystem|192.168.1.20" | awk '{
    if (NR==1) {
        print $0
    } else {
        free_gb = substr($4, 1, length($4)-1)
        if (free_gb >= 300) {
            status = "✅ GOOD"
        } else if (free_gb >= 200) {
            status = "⚠️  OK"
        } else {
            status = "🚨 LOW"
        }
        printf "%s %s %s %s %s %s\n", $1, $2, $3, $4, $5, status
    }
}'

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "2️⃣  TRIGGERING RADARR LIBRARY REFRESH"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -z "$RADARR_API_KEY" ]; then
    echo "❌ RADARR_API_KEY not found!"
    echo "   Please refresh manually at: $RADARR_URL"
else
    echo "🔄 Triggering Radarr library scan..."

    response=$(curl -s -X POST -H "X-Api-Key: $RADARR_API_KEY" -H "Content-Type: application/json" \
      "$RADARR_URL/api/v3/command" -d '{"name": "RefreshMonitoredDownloads"}' 2>&1)

    if echo "$response" | grep -q "id"; then
        echo "  ✅ Radarr refresh triggered successfully"
        echo "  💡 Monitor: $RADARR_URL/queue"
    else
        echo "  ⚠️  Could not trigger refresh automatically"
        echo "  📝 Please refresh manually at: $RADARR_URL"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "3️⃣  TRIGGERING SONARR LIBRARY REFRESH"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -z "$SONARR_API_KEY" ]; then
    echo "❌ SONARR_API_KEY not found!"
    echo "   Please refresh manually at: $SONARR_URL"
else
    echo "🔄 Triggering Sonarr library scan..."

    response=$(curl -s -X POST -H "X-Api-Key: $SONARR_API_KEY" -H "Content-Type: application/json" \
      "$SONARR_URL/api/v3/command" -d '{"name": "RefreshMonitoredDownloads"}' 2>&1)

    if echo "$response" | grep -q "id"; then
        echo "  ✅ Sonarr refresh triggered successfully"
        echo "  💡 Monitor: $SONARR_URL/queue"
    else
        echo "  ⚠️  Could not trigger refresh automatically"
        echo "  📝 Please refresh manually at: $SONARR_URL"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "4️⃣  HARRY POTTER RE-DOWNLOAD INSTRUCTIONS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "  📝 Manual Steps Required:"
echo ""
echo "  1. Open Radarr: $RADARR_URL"
echo "  2. Search for: \"Harry Potter\""
echo "  3. Add each movie (8 total):"
echo "     • Harry Potter and the Philosopher's Stone (2001)"
echo "     • Harry Potter and the Chamber of Secrets (2002)"
echo "     • Harry Potter and the Prisoner of Azkaban (2004)"
echo "     • Harry Potter and the Goblet of Fire (2005)"
echo "     • Harry Potter and the Order of the Phoenix (2007)"
echo "     • Harry Potter and the Half-Blood Prince (2009)"
echo "     • Harry Potter and the Deathly Hallows: Part 1 (2010)"
echo "     • Harry Potter and the Deathly Hallows: Part 2 (2011)"
echo ""
echo "  4. Quality Profile: 1080p BluRay (NOT 4K!)"
echo "  5. Click \"Add and Search\" for each"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "📊 SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "  Verified Deleted: $deleted_count"
echo "  Still Exists: $still_exists"
echo ""

if [ "$still_exists" -eq 0 ]; then
    echo "  ✅ All deletions verified successfully!"
else
    echo "  ⚠️  Some items still exist - please delete via File Station"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🔗 USEFUL LINKS"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Radarr: $RADARR_URL"
echo "  Sonarr: $SONARR_URL"
echo "  Synology File Station: http://192.168.1.20:5000"
echo "  Plex: http://192.168.1.11:32400/web"
echo ""

echo "✅ Verification complete!"

