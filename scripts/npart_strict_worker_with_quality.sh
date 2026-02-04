#!/usr/bin/env bash
#
# Enhanced Strict N-part sampling worker (one file) with QUALITY detection.
# - Decodes N evenly-spaced slices of length SLICE_SECONDS.
# - Uses strict ffmpeg settings: -loglevel error -xerror -sn -dn
# - Any non-zero exit or any stderr output at loglevel=error counts as a "hit".
# - NEW: Checks for low-quality indicators (filename patterns, bitrate)
# - NEW: Can skip corruption checks if file already scanned (quality-only mode)
# - TIMEOUT per slice is tracked separately.
#
# Output format (pipe-delimited):
#   STATUS|hits=<n>|timeouts=<n>|quality_hits=<n>|secs=<n>|parts=<n>|slice=<n>|<basename>|<fullpath>
#
set -euo pipefail

RESULTS_FILE="${1:?results file required}"
PARTS="${2:-20}"
SLICE_SECONDS="${3:-10}"
TIMEOUT_PER_SLICE="${4:-120}"
FILE="${5:?file path required}"
QUALITY_ONLY="${6:-0}"  # If 1, skip corruption checks, only run quality checks

if [[ ! -f "$FILE" ]]; then
  exit 0
fi

base="$(basename "$FILE")"
start="$(date +%s)"

# Reduce impact on other services.
RUN_PREFIX=()
command -v ionice >/dev/null 2>&1 && RUN_PREFIX+=(ionice -c2 -n7)
RUN_PREFIX+=(nice -n 10)

dur_raw="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$FILE" 2>/dev/null || true)"
dur="$(awk -v d="${dur_raw:-0}" 'BEGIN{printf "%d", (d+0.5)}')"
if [[ "$dur" -le 0 ]]; then
  dur=3600
fi

# Validate PARTS
if ! [[ "$PARTS" =~ ^[0-9]+$ ]] || [[ "$PARTS" -le 0 ]]; then
  PARTS=20
fi

hits=0
timeouts=0
quality_hits=0

run_slice() {
  local offset="$1"
  local use_eof="$2" # 0/1
  local out rc
  rc=0
  if [[ "$use_eof" == "1" ]]; then
    out="$(timeout "$TIMEOUT_PER_SLICE" "${RUN_PREFIX[@]}" ffmpeg -hide_banner -nostats -nostdin -loglevel error -xerror -sn -dn -sseof "-${SLICE_SECONDS}" -i "$FILE" -t "$SLICE_SECONDS" -f null - 2>&1)" || rc=$?
  else
    out="$(timeout "$TIMEOUT_PER_SLICE" "${RUN_PREFIX[@]}" ffmpeg -hide_banner -nostats -nostdin -loglevel error -xerror -sn -dn -ss "$offset" -i "$FILE" -t "$SLICE_SECONDS" -f null - 2>&1)" || rc=$?
  fi

  if [[ "$rc" -eq 124 ]]; then
    timeouts=$((timeouts + 1))
    return 0
  fi
  if [[ "$rc" -ne 0 || -n "$out" ]]; then
    hits=$((hits + 1))
  fi
  return 0
}

# Quality detection function
check_quality() {
  local file="$1"
  local basename="$2"

  # Check for genuinely low-quality indicators in filename (case-insensitive)
  # REMOVED: WEBRip/WEB-DL (can be high quality from streaming services)
  # REMOVED: WEBRip from patterns - many legitimate high-quality releases use this
  local low_quality_patterns="HDTV|TS|TELESYNC|SCREENER|DVDSCR|CAM|TELECINE|R5|R6"
  if echo "$basename" | grep -qiE "$low_quality_patterns"; then
    quality_hits=$((quality_hits + 1))
    return 0
  fi

  # Get codec first (affects bitrate thresholds)
  local codec
  codec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$file" 2>/dev/null || echo "unknown")"

  # Check bitrate (requires ffprobe)
  local bitrate_raw size_raw
  bitrate_raw="$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=nw=1:nk=1 "$file" 2>/dev/null || true)"
  size_raw="$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")"

  if [[ -n "$bitrate_raw" ]] && [[ "$bitrate_raw" =~ ^[0-9]+$ ]] && [[ "$bitrate_raw" -gt 0 ]]; then
    # Bitrate is in bps, convert to Mbps
    local bitrate_mbps
    bitrate_mbps=$(awk -v br="$bitrate_raw" 'BEGIN{printf "%.0f", br/1000000}')

    # Get resolution to determine threshold
    local width
    width="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nw=1:nk=1 "$file" 2>/dev/null || echo "0")"

    # Codec-aware thresholds: HEVC/x265 is more efficient, needs lower bitrate for same quality
    local threshold=3000  # Default 3 Mbps for H.264/AVC
    if [[ "$codec" =~ ^(hevc|h265|x265)$ ]]; then
      # HEVC is ~50% more efficient, so thresholds are lower
      if [[ "$width" -ge 1920 ]]; then
        threshold=1800  # 1080p HEVC: flag if < 1.8 Mbps (vs 3 Mbps for H.264)
      elif [[ "$width" -ge 1280 ]]; then
        threshold=1200  # 720p HEVC: flag if < 1.2 Mbps (vs 2 Mbps for H.264)
      else
        threshold=1500  # Other resolutions: 1.5 Mbps for HEVC
      fi
    else
      # H.264/AVC thresholds (original)
      if [[ "$width" -ge 1920 ]]; then
        threshold=3000  # 1080p H.264: flag if < 3 Mbps
      elif [[ "$width" -ge 1280 ]]; then
        threshold=2000  # 720p H.264: flag if < 2 Mbps
      fi
    fi

    if [[ "$bitrate_mbps" -lt "$threshold" ]] && [[ "$bitrate_mbps" -gt 0 ]]; then
      quality_hits=$((quality_hits + 1))
      return 0
    fi
  else
    # Fallback: check file size vs duration ratio (codec-aware)
    if [[ "$dur" -gt 0 ]] && [[ "$size_raw" -gt 0 ]]; then
      local mb_per_minute
      mb_per_minute=$(awk -v s="$size_raw" -v d="$dur" 'BEGIN{printf "%.0f", (s/1048576)/(d/60)}')

      # Codec-aware threshold: HEVC files are smaller but can still be high quality
      local size_threshold=30  # Default 30 MB/min for H.264
      if [[ "$codec" =~ ^(hevc|h265|x265)$ ]]; then
        size_threshold=20  # HEVC: flag if < 20 MB/min (more efficient codec)
      fi

      if [[ "$mb_per_minute" -lt "$size_threshold" ]] && [[ "$mb_per_minute" -gt 0 ]]; then
        quality_hits=$((quality_hits + 1))
        return 0
      fi
    fi
  fi

  return 1
}

# Run corruption checks only if not in quality-only mode
if [[ "$QUALITY_ONLY" != "1" ]]; then
  step="$(awk -v d="$dur" -v n="$PARTS" 'BEGIN{printf "%.6f", d/n}')"

  for ((i=0; i<PARTS; i++)); do
    off="$(awk -v s="$step" -v i="$i" 'BEGIN{printf "%d", (s*i)}')"
    use_eof=0
    if [[ "$off" -ge $((dur - SLICE_SECONDS)) ]]; then
      use_eof=1
      off=$((dur - SLICE_SECONDS))
      [[ "$off" -lt 0 ]] && off=0
    fi
    run_slice "$off" "$use_eof"
  done
else
  # Quality-only mode: skip all decode checks (much faster)
  hits=0
  timeouts=0
fi

# Check quality (always run, even in quality-only mode)
# Note: || true prevents script exit on return code 1 (no quality issues found)
check_quality "$FILE" "$base" || true

end="$(date +%s)"
secs="$((end-start))"

status="OK"
# Corruption takes priority
if [[ "$hits" -ge 1 ]]; then
  status="SUSPICIOUS"
fi
# Quality issues also mark as SUSPICIOUS (so they get flagged for review)
if [[ "$quality_hits" -ge 1 ]] && [[ "$status" == "OK" ]]; then
  status="SUSPICIOUS"
fi
if [[ "$timeouts" -ge 1 && "$status" == "OK" ]]; then
  status="TIMEOUT"
fi

line="${status}|hits=${hits}|timeouts=${timeouts}|quality_hits=${quality_hits}|secs=${secs}|parts=${PARTS}|slice=${SLICE_SECONDS}|${base}|${FILE}"

{
  flock -w 30 200 || exit 1
  printf '%s\n' "$line" >> "$RESULTS_FILE"
} 200>"${RESULTS_FILE}.lock"

