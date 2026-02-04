#!/bin/bash
#
# DEPRECATED (Safety):
# This repo now uses QUARANTINE instead of deletion to avoid irreversible mistakes.
# Use: scripts/quarantine_corrupt_media.sh
#

RESULTS="/tmp/stable_scan_results_v2.txt"
DELETED_LOG="/tmp/deleted_corrupt_$(date +%Y%m%d_%H%M%S).txt"
RADARR_ENDPOINT="http://192.168.1.11:7878/api/v3"
SONARR_ENDPOINT="http://192.168.1.11:8989/api/v3"

# SAFETY: never allow deleting these root media directories
ROOT_MEDIA_DIRS=(
  "/external/media/Movies"
  "/external/media/TV"
  "/external/media/Kids Movies"
  "/external/media/Kids TV"
  "/home/youruser/synology/Media/Movies"
  "/home/youruser/synology/Media/TV Shows"
  "/home/youruser/synology/Media/Movies - Kids"
  "/home/youruser/synology/Media/TV Shows - Kids"
)

realpath_safe() {
  # Prefer readlink -f if present; fall back to python.
  if command -v readlink >/dev/null 2>&1; then
    readlink -f -- "$1" 2>/dev/null || echo "$1"
  else
    python3 - <<'PY' "$1" 2>/dev/null || echo "$1"
import os, sys
print(os.path.realpath(sys.argv[1]))
PY
  fi
}

is_root_media_dir() {
  local p rp root rroot
  p="$1"
  rp="$(realpath_safe "$p")"
  for root in "${ROOT_MEDIA_DIRS[@]}"; do
    rroot="$(realpath_safe "$root")"
    if [[ "$rp" == "$rroot" ]]; then
      return 0
    fi
  done
  return 1
}

movie_folder_for_file() {
  # Returns the movie folder to delete, or empty string if we should NOT delete a folder.
  # A folder is only eligible if it is a direct child of a known root movie dir.
  local f d parent rp rparent
  f="$1"
  d="$(dirname "$f")"
  rp="$(realpath_safe "$d")"

  for parent in "/external/media/Movies" "/external/media/Kids Movies" "/home/youruser/synology/Media/Movies" "/home/youruser/synology/Media/Movies - Kids"; do
    rparent="$(realpath_safe "$parent")"
    # Eligible only if dirname's parent is exactly the root movie dir
    if [[ "$(dirname "$rp")" == "$rparent" ]]; then
      # And NEVER if that dirname itself is a root dir
      if is_root_media_dir "$rp"; then
        echo ""
        return 0
      fi
      echo "$rp"
      return 0
    fi
  done

  # If the file sits directly in the root (e.g. /external/media/Kids Movies/file.avi),
  # dirname will equal the root -> do not delete the folder.
  echo ""
}

tv_episode_should_delete_folder() {
  # For TV: we never delete folders in this script; only delete the file.
  return 1
}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🚫 DEPRECATED: USE QUARANTINE SCRIPT (NO DELETION)           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "This script is deprecated to prevent accidental data loss."
echo "Use instead:"
echo "  scripts/quarantine_corrupt_media.sh"
echo ""
exit 1

# Extract API keys from containers
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  EXTRACTING API KEYS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RADARR_KEY=$(docker exec radarr cat /config/config.xml 2>/dev/null | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')
SONARR_KEY=$(docker exec sonarr cat /config/config.xml 2>/dev/null | grep "<ApiKey>" | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/')

if [ -z "$RADARR_KEY" ]; then
    echo "❌ Failed to extract Radarr API key"
    exit 1
fi

if [ -z "$SONARR_KEY" ]; then
    echo "❌ Failed to extract Sonarr API key"
    exit 1
fi

echo "✅ Radarr API key: ${RADARR_KEY:0:8}..."
echo "✅ Sonarr API key: ${SONARR_KEY:0:8}..."

# Verify scan results exist
if [ ! -f "$RESULTS" ]; then
    echo "❌ Scan results not found: $RESULTS"
    exit 1
fi

# Count corrupt files
total_corrupt=$(grep -c '^CORRUPT' "$RESULTS")
echo ""
echo "Found $total_corrupt corrupted files to delete"

# Categorize
nas_movies=$(awk -F'|' '$1=="CORRUPT" && $5 ~ /^\/home\/youruser\/synology\/media\/Movies/ {print}' "$RESULTS" | wc -l)
nas_tv=$(awk -F'|' '$1=="CORRUPT" && $5 ~ /^\/home\/youruser\/synology\/media\/TV Shows/ {print}' "$RESULTS" | wc -l)
nas_kids=$(awk -F'|' '$1=="CORRUPT" && $5 ~ /^\/home\/youruser\/synology\/media\/Movies - Kids/ {print}' "$RESULTS" | wc -l)
usb_movies=$(awk -F'|' '$1=="CORRUPT" && $5 ~ /^\/external\/media\/Movies/ {print}' "$RESULTS" | wc -l)
usb_tv=$(awk -F'|' '$1=="CORRUPT" && $5 ~ /^\/external\/media\/TV/ {print}' "$RESULTS" | wc -l)
usb_kids=$(awk -F'|' '$1=="CORRUPT" && $5 ~ /^\/external\/media\/Kids Movies/ {print}' "$RESULTS" | wc -l)

echo ""
echo "Breakdown:"
echo "  NAS Movies:      $nas_movies"
echo "  NAS TV Shows:    $nas_tv"
echo "  NAS Kids Movies: $nas_kids"
echo "  USB Movies:      $usb_movies"
echo "  USB TV:          $usb_tv"
echo "  USB Kids Movies: $usb_kids"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  STORAGE BEFORE DELETION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

df -h /home/youruser/synology/Media | tail -1 | awk '{printf "NAS:  %s / %s (%s used)\n", $3, $2, $5}'
df -h /external/media | tail -1 | awk '{printf "USB:  %s / %s (%s used)\n", $3, $2, $5}'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  DELETING CORRUPT FILES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  This will delete $total_corrupt files (~250 GB)"
echo ""
echo "Press ENTER to continue, or Ctrl+C to cancel..."
read

deleted_count=0
failed_count=0

: > "$DELETED_LOG"

echo ""
echo "Preflight safety check: ensuring no root media directories are deletable..."
echo "  (If anything tries to delete a root folder, the script will abort.)"
echo ""

while IFS='|' read -r status hard nal filename filepath; do
    if [ -f "$filepath" ]; then
        # Decide safe deletion target
        target_dir="$(movie_folder_for_file "$filepath")"

        if [[ -n "$target_dir" ]]; then
            # Final guard
            if is_root_media_dir "$target_dir"; then
                echo "❌ SAFETY ABORT: would delete root media dir: $target_dir"
                exit 1
            fi
            echo "  🗑️  Deleting movie folder: $(basename "$target_dir")"
            rm -rf -- "$target_dir"
            if [ ! -d "$target_dir" ]; then
                echo "$filepath" >> "$DELETED_LOG"
                ((deleted_count++))
            else
                echo "     ❌ Failed to delete: $target_dir"
                ((failed_count++))
            fi
        else
            # Default: delete file only (TV episodes, root-level files, anything uncertain)
            if is_root_media_dir "$(dirname "$filepath")"; then
                echo "  🗑️  Deleting file in root folder (safe): $filename"
            else
                echo "  🗑️  Deleting file: $filename"
            fi
            rm -f -- "$filepath"
            if [ ! -f "$filepath" ]; then
                echo "$filepath" >> "$DELETED_LOG"
                ((deleted_count++))
            else
                echo "     ❌ Failed to delete: $filepath"
                ((failed_count++))
            fi
        fi
    else
        echo "  ⚠️  Not found: $filename"
    fi
done < <(grep '^CORRUPT' "$RESULTS")

echo ""
echo "Deletion summary: $deleted_count deleted, $failed_count failed"
echo "Deleted files logged to: $DELETED_LOG"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  STORAGE AFTER DELETION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

df -h /home/youruser/synology/Media | tail -1 | awk '{printf "NAS:  %s / %s (%s used)\n", $3, $2, $5}'
df -h /external/media | tail -1 | awk '{printf "USB:  %s / %s (%s used)\n", $3, $2, $5}'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  TRIGGERING RADARR REFRESH & SEARCH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🎬 Triggering Radarr refresh..."
curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" \
    "${RADARR_ENDPOINT}/command" \
    -d '{"name": "RefreshMovie"}' > /dev/null
echo "   ✅ Radarr refresh triggered"

echo ""
echo "Waiting 3 minutes for Radarr to process file changes..."
sleep 180

echo ""
echo "🔍 Triggering Radarr missing movie search..."
curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" \
    "${RADARR_ENDPOINT}/command" \
    -d '{"name": "MissingMoviesSearch", "filterKey": "monitored", "filterValue": "true"}' > /dev/null
echo "   ✅ Radarr search triggered"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  TRIGGERING SONARR REFRESH & SEARCH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📺 Triggering Sonarr refresh..."
curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" \
    "${SONARR_ENDPOINT}/command" \
    -d '{"name": "RefreshSeries"}' > /dev/null
echo "   ✅ Sonarr refresh triggered"

echo ""
echo "Waiting 3 minutes for Sonarr to process file changes..."
sleep 180

echo ""
echo "🔍 Triggering Sonarr missing episode search..."
curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" \
    "${SONARR_ENDPOINT}/command" \
    -d '{"name": "MissingEpisodeSearch"}' > /dev/null
echo "   ✅ Sonarr search triggered"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ DELETION & RE-DOWNLOAD COMPLETE                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Summary:"
echo "  • Deleted $deleted_count corrupted files (~250GB)"
echo "  • Triggered Radarr/Sonarr refresh (completed)"
echo "  • Triggered automatic searches for missing content"
echo ""
echo "Next Steps:"
echo "  1. Monitor Radarr/Sonarr for download progress (10-30 min)"
echo "  2. Check that movies/shows are 'monitored' in Radarr/Sonarr"
echo "  3. Verify re-downloaded files play correctly"
echo ""
echo "Log files:"
echo "  • Deleted files: $DELETED_LOG"
echo "  • Scan results:  $RESULTS"
echo ""

