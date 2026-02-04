#!/usr/bin/env bash
#
# Strict N-part sampling worker (one file).
# - Decodes N evenly-spaced slices of length SLICE_SECONDS.
# - Uses strict ffmpeg settings: -loglevel error -xerror -sn -dn
# - Any non-zero exit or any stderr output at loglevel=error counts as a "hit".
# - TIMEOUT per slice is tracked separately.
#
# Output format (pipe-delimited):
#   STATUS|hits=<n>|timeouts=<n>|secs=<n>|parts=<n>|slice=<n>|<basename>|<fullpath>
#
set -euo pipefail

RESULTS_FILE="${1:?results file required}"
PARTS="${2:-20}"
SLICE_SECONDS="${3:-10}"
TIMEOUT_PER_SLICE="${4:-120}"
FILE="${5:?file path required}"

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

end="$(date +%s)"
secs="$((end-start))"

status="OK"
if [[ "$hits" -ge 1 ]]; then
  status="SUSPICIOUS"
fi
if [[ "$timeouts" -ge 1 && "$status" == "OK" ]]; then
  status="TIMEOUT"
fi

line="${status}|hits=${hits}|timeouts=${timeouts}|secs=${secs}|parts=${PARTS}|slice=${SLICE_SECONDS}|${base}|${FILE}"

{
  flock -w 30 200 || exit 1
  printf '%s\n' "$line" >> "$RESULTS_FILE"
} 200>"${RESULTS_FILE}.lock"


