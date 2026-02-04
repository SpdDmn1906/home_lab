#!/usr/bin/env bash
#
# Simulate N-part slice decoding on a single file to estimate whether sampling
# would catch a known corruption (e.g. Gumball S02E04) and how long it takes.
#
# It runs ffmpeg in strict mode:
#   -loglevel error -xerror -sn -dn
# so any real decode/read issues will fail the slice.
#
# Usage:
#   ./simulate_npart_sampling.sh "/path/to/file.mkv" "15,20,25" 15
#
# Args:
#   1) FILE (required)
#   2) PARTS_CSV (optional, default "15,20,25")
#   3) SLICE_SECONDS (optional, default 15)
#
# Env knobs:
#   TIMEOUT_PER_SLICE (default 120)  # seconds
#
set -euo pipefail

FILE="${1:?file required}"
PARTS_CSV="${2:-15,20,25}"
SLICE_SECONDS="${3:-15}"
TIMEOUT_PER_SLICE="${TIMEOUT_PER_SLICE:-120}"

if [[ ! -f "$FILE" ]]; then
  echo "❌ File not found: $FILE" >&2
  exit 2
fi

dur_raw="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$FILE" 2>/dev/null || true)"
if [[ -z "${dur_raw}" ]]; then
  echo "❌ Could not read duration via ffprobe: $FILE" >&2
  exit 3
fi

duration="$(awk -v d="$dur_raw" 'BEGIN{printf "%d", (d+0.5)}')"
if [[ "$duration" -le 0 ]]; then
  echo "❌ Invalid duration: $dur_raw" >&2
  exit 4
fi

echo "File: $FILE"
echo "Duration: ${duration}s"
echo "Slice seconds: ${SLICE_SECONDS}s"
echo "Timeout per slice: ${TIMEOUT_PER_SLICE}s"
echo ""

IFS=',' read -r -a parts_list <<< "$PARTS_CSV"

tmpdir="/tmp/simulate_npart_$$"
mkdir -p "$tmpdir"
trap 'rm -rf "$tmpdir"' EXIT

printf "%-8s %-10s %-10s %-10s %s\n" "PARTS" "HITS" "SLICES" "WALL(s)" "FIRST_HIT"
printf "%-8s %-10s %-10s %-10s %s\n" "-----" "----" "------" "-------" "---------"

run_slice() {
  local offset="$1"
  local use_eof="$2" # 0/1
  local out rc
  rc=0
  if [[ "$use_eof" == "1" ]]; then
    out="$(timeout "$TIMEOUT_PER_SLICE" ffmpeg -hide_banner -nostats -nostdin -loglevel error -xerror -sn -dn -sseof "-${SLICE_SECONDS}" -i "$FILE" -t "$SLICE_SECONDS" -f null - 2>&1)" || rc=$?
  else
    out="$(timeout "$TIMEOUT_PER_SLICE" ffmpeg -hide_banner -nostats -nostdin -loglevel error -xerror -sn -dn -ss "$offset" -i "$FILE" -t "$SLICE_SECONDS" -f null - 2>&1)" || rc=$?
  fi

  # Return 0 for OK, 1 for BAD, 2 for TIMEOUT
  if [[ "$rc" -eq 124 ]]; then
    echo "TIMEOUT|offset=${offset}|$out"
    return 2
  fi
  if [[ "$rc" -ne 0 || -n "$out" ]]; then
    echo "BAD|offset=${offset}|$out"
    return 1
  fi
  echo "OK|offset=${offset}|"
  return 0
}

for N in "${parts_list[@]}"; do
  # Validate integer N
  if ! [[ "$N" =~ ^[0-9]+$ ]] || [[ "$N" -le 0 ]]; then
    echo "Skipping invalid parts value: $N" >&2
    continue
  fi

  start="$(date +%s)"
  hits=0
  first_hit="(none)"
  slices=0

  step="$(awk -v d="$duration" -v n="$N" 'BEGIN{printf "%.6f", d/n}')"
  first_err_file="$tmpdir/first_err_${N}.txt"
  : > "$first_err_file"

  for ((i=0; i<N; i++)); do
    # Evenly spaced offsets over [0, duration)
    off="$(awk -v s="$step" -v i="$i" 'BEGIN{printf "%d", (s*i)}')"
    use_eof=0
    # If too close to end for a forward slice, use EOF sampling
    if [[ "$off" -ge $((duration - SLICE_SECONDS)) ]]; then
      use_eof=1
      off=$((duration - SLICE_SECONDS))
      [[ "$off" -lt 0 ]] && off=0
    fi

    slices=$((slices + 1))
    result="$(run_slice "$off" "$use_eof" || true)"
    if [[ "$result" == TIMEOUT* ]]; then
      hits=$((hits + 1))
      if [[ "$first_hit" == "(none)" ]]; then
        first_hit="TIMEOUT@${off}s"
        printf "%s\n" "$result" | cut -d'|' -f3- > "$first_err_file"
      fi
    elif [[ "$result" == BAD* ]]; then
      hits=$((hits + 1))
      if [[ "$first_hit" == "(none)" ]]; then
        first_hit="BAD@${off}s"
        printf "%s\n" "$result" | cut -d'|' -f3- > "$first_err_file"
      fi
    fi
  done

  end="$(date +%s)"
  wall="$((end-start))"

  printf "%-8s %-10s %-10s %-10s %s\n" "$N" "$hits" "$slices" "$wall" "$first_hit"

  if [[ -s "$first_err_file" ]]; then
    echo "  First error lines ($N parts):"
    head -8 "$first_err_file" | sed 's/^/  | /'
  fi
done


