#!/usr/bin/env bash
#
# Quarantine (NOT delete) confirmed-corrupt media and trigger Radarr/Sonarr refresh/search.
# Safe-by-default: moves files/folders into a timestamped quarantine directory so it is reversible.
#
# Usage (server):
#   RESULTS=/tmp/stable_scan_results_v2.txt ./quarantine_corrupt_media.sh
#
set -euo pipefail

RESULTS="${RESULTS:-/tmp/stable_scan_results_v2.txt}"

# Where to quarantine (safe defaults)
TS="$(date +%Y%m%d_%H%M%S)"
# Preferred locations
QUAR_USB="/external/media/_quarantine/${TS}"
QUAR_NAS_PREFERRED="/data/synology/Media/quarantine/${TS}"
# Fallback if NAS quarantine path isn't writable
QUAR_NAS_FALLBACK="/external/media/_quarantine/NAS_FALLBACK/${TS}"

# Service endpoints (host network)
RADARR_ENDPOINT="http://192.168.1.11:7878/api/v3"
SONARR_ENDPOINT="http://192.168.1.11:8989/api/v3"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🧊 QUARANTINE CORRUPT MEDIA (NO DELETION) + REGRAB         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [[ ! -f "$RESULTS" ]]; then
  echo "❌ RESULTS file not found: $RESULTS"
  exit 1
fi

total_corrupt="$(grep -c '^CORRUPT' "$RESULTS" 2>/dev/null || echo 0)"
echo "CORRUPT entries in results: $total_corrupt"
echo ""

if [[ "$total_corrupt" -le 0 ]]; then
  echo "Nothing to quarantine."
  exit 0
fi

ensure_dir() {
  local d="$1"
  mkdir -p "$d" 2>/dev/null || return 1
  chmod 777 "$d" 2>/dev/null || true
  return 0
}

echo "Preparing quarantine directory (USB):"
echo "  $QUAR_USB"
if ! ensure_dir "$QUAR_USB"; then
  echo "❌ Cannot create USB quarantine directory: $QUAR_USB"
  exit 1
fi

# NAS quarantine is prepared lazily only if we actually need it.
NAS_QUAR_READY=0
NAS_QUAR_PATH=""
echo ""

echo "Extracting API keys from containers..."
RADARR_KEY="$(docker exec radarr cat /config/config.xml 2>/dev/null | awk -F'[<>]' '/<ApiKey>/{print $3; exit}' || true)"
SONARR_KEY="$(docker exec sonarr cat /config/config.xml 2>/dev/null | awk -F'[<>]' '/<ApiKey>/{print $3; exit}' || true)"

if [[ -z "$RADARR_KEY" || -z "$SONARR_KEY" ]]; then
  echo "❌ Could not extract Radarr/Sonarr API keys."
  exit 1
fi

LOG="/tmp/quarantined_corrupt_${TS}.txt"
: > "$LOG"

echo "Quarantining (moving) corrupt items..."
echo "Log: $LOG"
echo ""

move_path() {
  local src="$1"
  local dst_root="$2"

  # Preserve relative path structure inside quarantine where possible
  local dst="$dst_root${src}"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  mkdir -p "$dst_dir"

  # If it's a file: mv it.
  if [[ -f "$src" ]]; then
    mv -n -- "$src" "$dst"
    echo "MOVED_FILE|$src|$dst" >> "$LOG"
    return 0
  fi

  # If it's a directory: move whole folder.
  if [[ -d "$src" ]]; then
    # Move directory as a unit into quarantine, preserving its full path.
    mkdir -p "$(dirname "$dst")"
    mv -n -- "$src" "$dst"
    echo "MOVED_DIR|$src|$dst" >> "$LOG"
    return 0
  fi

  echo "MISSING|$src" >> "$LOG"
  return 0
}

# For movies: quarantine the movie folder if it is one-level deep under a movie root; otherwise quarantine just the file.
movie_folder_for_file() {
  local f="$1"
  local d
  d="$(dirname "$f")"
  # Only treat folder as movie folder if its parent is a known movie root (prevents root-folder moves).
  case "$(dirname "$d")" in
    "/external/media/Movies"|"/external/media/Kids Movies"|"/home/youruser/synology/Media/Movies"|"/home/youruser/synology/Media/Movies - Kids")
      echo "$d"
      return 0
      ;;
  esac
  echo ""
}

quarantined=0

while IFS='|' read -r status hard nal filename filepath; do
  [[ "$status" != "CORRUPT" ]] && continue

  # Choose quarantine root based on location
  if [[ "$filepath" == /home/youruser/synology/* ]]; then
    if [[ "$NAS_QUAR_READY" -eq 0 ]]; then
      echo "Preparing NAS quarantine directory..."
      if ensure_dir "$QUAR_NAS_PREFERRED"; then
        NAS_QUAR_PATH="$QUAR_NAS_PREFERRED"
        echo "  ✅ Using NAS quarantine: $NAS_QUAR_PATH"
      else
        ensure_dir "$QUAR_NAS_FALLBACK"
        NAS_QUAR_PATH="$QUAR_NAS_FALLBACK"
        echo "  ⚠️  NAS quarantine not writable; using fallback: $NAS_QUAR_PATH"
      fi
      NAS_QUAR_READY=1
      echo ""
    fi
    dst_root="$NAS_QUAR_PATH"
  elif [[ "$filepath" == /external/media/* ]]; then
    dst_root="$QUAR_USB"
  else
    # Unknown root; quarantine under USB quarantine by default
    dst_root="$QUAR_USB"
  fi

  target="$filepath"
  mf="$(movie_folder_for_file "$filepath")"
  if [[ -n "$mf" ]]; then
    target="$mf"
  fi

  move_path "$target" "$dst_root"
  quarantined=$((quarantined + 1))
done < <(grep '^CORRUPT' "$RESULTS")

echo ""
echo "Quarantine done. Items processed: $quarantined"
echo "Quarantine log: $LOG"
echo ""

echo "Triggering Radarr refresh + missing search (monitored)..."
curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" \
  "${RADARR_ENDPOINT}/command" -d '{"name":"RefreshMovie"}' >/dev/null || true
curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" \
  "${RADARR_ENDPOINT}/command" -d '{"name":"MissingMoviesSearch","filterKey":"monitored","filterValue":"true"}' >/dev/null || true

echo "Triggering Sonarr refresh + missing search..."
curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" \
  "${SONARR_ENDPOINT}/command" -d '{"name":"RefreshSeries"}' >/dev/null || true
curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" \
  "${SONARR_ENDPOINT}/command" -d '{"name":"MissingEpisodeSearch"}' >/dev/null || true

echo ""
echo "✅ Quarantine + refresh/search triggered."
echo "   Review quarantined items before any permanent deletion."


