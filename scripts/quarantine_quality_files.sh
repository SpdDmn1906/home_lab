#!/usr/bin/env bash
#
# Quarantine files flagged as low quality (after re-scan with updated logic)
# Option C: For HDTV files, only quarantine if they also have low bitrate/size
#
# Usage:
#   RESULTS=/path/to/rescan_results.txt ./quarantine_quality_files.sh
#
set -euo pipefail

RESULTS="${RESULTS:-/home/youruser/stable_scan/results/quality_rescan_latest.txt}"

# Where to quarantine (safe defaults)
TS="$(date +%Y%m%d_%H%M%S)"
QUAR_USB="/external/media/_quarantine/quality_${TS}"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🧊 QUARANTINE LOW-QUALITY MEDIA (OPTION C)                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [[ ! -f "$RESULTS" ]]; then
  echo "❌ RESULTS file not found: $RESULTS"
  exit 1
fi

total_flagged="$(grep -c '^SUSPICIOUS' "$RESULTS" 2>/dev/null || echo 0)"
echo "SUSPICIOUS (low-quality) entries in results: $total_flagged"
echo ""

if [[ "$total_flagged" -le 0 ]]; then
  echo "Nothing to quarantine."
  exit 0
fi

# Create quarantine directory
mkdir -p "$QUAR_USB" 2>/dev/null || {
  echo "❌ Cannot create quarantine directory: $QUAR_USB"
  exit 1
}

LOG="/tmp/quarantined_quality_${TS}.txt"
: > "$LOG"

echo "Quarantining (moving) low-quality items (Option C: HDTV only if low bitrate/size)..."
echo "Quarantine: $QUAR_USB"
echo "Log: $LOG"
echo ""

move_path() {
  local src="$1"
  local dst_root="$2"

  # Preserve relative path structure inside quarantine
  local dst="$dst_root${src}"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  mkdir -p "$dst_dir"

  # If it's a file: mv it.
  if [[ -f "$src" ]]; then
    if [[ -f "$dst" ]]; then
      echo "⚠️  Destination exists, skipping: $dst"
      return 1
    fi
    mv -n -- "$src" "$dst" 2>/dev/null && {
      echo "MOVED_FILE|$src|$dst" >> "$LOG"
      return 0
    }
    return 1
  fi

  # If it's a directory: move whole folder.
  if [[ -d "$src" ]]; then
    if [[ -d "$dst" ]]; then
      echo "⚠️  Destination exists, skipping: $dst"
      return 1
    fi
    mkdir -p "$(dirname "$dst")"
    mv -n -- "$src" "$dst" 2>/dev/null && {
      echo "MOVED_DIR|$src|$dst" >> "$LOG"
      return 0
    }
    return 1
  fi

  echo "⚠️  Not a file or directory: $src"
  return 1
}

# Helper function to check if file has low bitrate/size (for HDTV filtering)
has_low_quality_metrics() {
  local filepath="$1"
  local basename="$2"

  # Get codec
  local codec
  codec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$filepath" 2>/dev/null || echo "unknown")"

  # Check bitrate
  local bitrate_raw
  bitrate_raw="$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=nw=1:nk=1 "$filepath" 2>/dev/null || echo "N/A")"

  if [[ "$bitrate_raw" =~ ^[0-9]+$ ]] && [[ "$bitrate_raw" -gt 0 ]]; then
    local bitrate_mbps
    bitrate_mbps=$(awk -v br="$bitrate_raw" 'BEGIN{printf "%.0f", br/1000000}')

    # Codec-aware thresholds
    local threshold=3000  # H.264 default
    if [[ "$codec" =~ ^(hevc|h265|x265)$ ]]; then
      threshold=1800  # HEVC threshold
    fi

    if [[ "$bitrate_mbps" -lt "$threshold" ]]; then
      return 0  # Has low bitrate
    fi
  else
    # Fallback: check file size/duration
    local size_raw dur_raw dur
    size_raw="$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath" 2>/dev/null || echo "0")"
    dur_raw="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$filepath" 2>/dev/null || echo "0")"
    # Convert duration to integer (truncate decimal)
    dur="$(awk -v d="${dur_raw:-0}" 'BEGIN{printf "%d", (d+0.5)}')"

    if [[ "$dur" -gt 0 ]] && [[ "$size_raw" -gt 0 ]]; then
      local mb_per_minute threshold_size
      mb_per_minute=$(awk -v s="$size_raw" -v d="$dur" 'BEGIN{printf "%.0f", (s/1048576)/(d/60)}')

      threshold_size=30  # H.264 default
      if [[ "$codec" =~ ^(hevc|h265|x265)$ ]]; then
        threshold_size=20  # HEVC threshold
      fi

      if [[ "$mb_per_minute" -lt "$threshold_size" ]]; then
        return 0  # Has low size/duration ratio
      fi
    fi
  fi

  return 1  # Does not have low quality metrics
}

moved_count=0
failed_count=0
skipped_hdtv_count=0

# Process SUSPICIOUS entries
while IFS='|' read -r status _ _ _ _ _ _ _ filepath; do
  if [[ "$status" != "SUSPICIOUS" ]] || [[ -z "$filepath" ]]; then
    continue
  fi

  basename="$(basename "$filepath")"

  # Option C: For HDTV files, only quarantine if they also have low bitrate/size
  if echo "$basename" | grep -qiE "hdtv"; then
    if ! has_low_quality_metrics "$filepath" "$basename"; then
      skipped_hdtv_count=$((skipped_hdtv_count + 1))
      echo "⏭️  Skipped HDTV (acceptable quality): $(basename "$filepath")"
      continue
    fi
  fi

  # Determine quarantine location based on file path
  if [[ "$filepath" =~ ^/external/media/ ]]; then
    # USB file - quarantine on USB
    if move_path "$filepath" "$QUAR_USB"; then
      moved_count=$((moved_count + 1))
      echo "✅ Quarantined: $(basename "$filepath")"
    else
      failed_count=$((failed_count + 1))
      echo "❌ Failed: $(basename "$filepath")"
    fi
  elif [[ "$filepath" =~ ^/home/youruser/synology/Media/ ]] || [[ "$filepath" =~ ^/data/synology/Media/ ]]; then
    # NAS file - quarantine on USB (NAS quarantine may not be writable)
    if move_path "$filepath" "$QUAR_USB"; then
      moved_count=$((moved_count + 1))
      echo "✅ Quarantined: $(basename "$filepath")"
    else
      failed_count=$((failed_count + 1))
      echo "❌ Failed: $(basename "$filepath")"
    fi
  else
    echo "⚠️  Unknown path pattern, skipping: $filepath"
    failed_count=$((failed_count + 1))
  fi
done < "$RESULTS"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    QUARANTINE SUMMARY                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Moved to quarantine: $moved_count"
echo "Failed: $failed_count"
echo "Skipped HDTV (acceptable quality): $skipped_hdtv_count"
echo "Quarantine location: $QUAR_USB"
echo "Log file: $LOG"
echo ""

if [[ "$moved_count" -gt 0 ]]; then
  echo "✅ Quarantine complete!"
  echo ""

  # Extract API keys and trigger Radarr/Sonarr refreshes
  echo "Triggering Radarr/Sonarr refreshes..."
  RADARR_KEY="$(docker exec radarr cat /config/config.xml 2>/dev/null | awk -F'[<>]' '/<ApiKey>/{print $3; exit}' || true)"
  SONARR_KEY="$(docker exec sonarr cat /config/config.xml 2>/dev/null | awk -F'[<>]' '/<ApiKey>/{print $3; exit}' || true)"

  if [[ -n "$RADARR_KEY" ]]; then
    RADARR_ENDPOINT="http://192.168.1.11:7878/api/v3"
    echo "  Triggering Radarr RefreshMovie..."
    curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" \
      "${RADARR_ENDPOINT}/command" -d '{"name":"RefreshMovie"}' >/dev/null || true
    echo "  Triggering Radarr MissingMoviesSearch..."
    curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $RADARR_KEY" \
      "${RADARR_ENDPOINT}/command" -d '{"name":"MissingMoviesSearch","filterKey":"monitored","filterValue":"true"}' >/dev/null || true
  fi

  if [[ -n "$SONARR_KEY" ]]; then
    SONARR_ENDPOINT="http://192.168.1.11:8989/api/v3"
    echo "  Triggering Sonarr RefreshSeries..."
    curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" \
      "${SONARR_ENDPOINT}/command" -d '{"name":"RefreshSeries"}' >/dev/null || true
    echo "  Triggering Sonarr MissingEpisodeSearch..."
    curl -s -X POST -H "Content-Type: application/json" -H "X-Api-Key: $SONARR_KEY" \
      "${SONARR_ENDPOINT}/command" -d '{"name":"MissingEpisodeSearch"}' >/dev/null || true
  fi

  echo ""
  echo "Next steps:"
  echo "  1. Review quarantined files in: $QUAR_USB"
  echo "  2. Radarr/Sonarr will detect missing files and search for replacements"
  echo "  3. If files are actually good quality, restore them from quarantine"
else
  echo "⚠️  No files were quarantined."
fi
