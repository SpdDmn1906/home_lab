#!/usr/bin/env bash
#
# Full-decode worker: scans ONE file by decoding the entire stream (no subtitles/data).
# Appends a single line to the results file with a lock for concurrency safety.
#
# Output format:
#   STATUS|rc=<n>|secs=<n>|<basename>|<fullpath>
#
set -euo pipefail

RESULTS_FILE="${1:?results file required}"
TIMEOUT_SECONDS="${2:-1200}"   # 20 min default per file
FILE="${3:?file path required}"

if [[ ! -f "$FILE" ]]; then
  exit 0
fi

base="$(basename "$FILE")"
start="$(date +%s)"

# Reduce impact on other services (Plex, calls, etc.)
RUN_PREFIX=()
command -v ionice >/dev/null 2>&1 && RUN_PREFIX+=(ionice -c2 -n7)
RUN_PREFIX+=(nice -n 10)

# Full decode, strict errors:
# - -sn -dn ignores subtitles/data (avoids PGS warnings)
# - -loglevel error emits only decode errors
# - -xerror makes ffmpeg exit non-zero on errors
out=""
rc=0
out="$(timeout "${TIMEOUT_SECONDS}" "${RUN_PREFIX[@]}" ffmpeg -hide_banner -nostats -nostdin -loglevel error -xerror -sn -dn -i "$FILE" -f null - 2>&1)" || rc=$?

end="$(date +%s)"
secs="$((end-start))"

status="OK"
if [[ "$rc" -eq 124 ]]; then
  status="TIMEOUT"
elif [[ "$rc" -ne 0 || -n "${out}" ]]; then
  status="CORRUPT"
fi

line="${status}|rc=${rc}|secs=${secs}|${base}|${FILE}"

{
  flock -w 30 200 || exit 1
  printf '%s\n' "$line" >> "$RESULTS_FILE"
} 200>"${RESULTS_FILE}.lock"


