#!/usr/bin/env bash
#
# Stable corruption scan runner (xargs-based)
# - Robust in screen sessions (no bash job orchestration / PID arrays)
# - Supports resume (skips files already present in results file)
#
# Usage (server):
#   WORKERS=8 SLICE=15 TIMEOUT=25 RESULTS=/tmp/stable_scan_results.txt ./stable_corruption_scan.sh
#
set -euo pipefail
set +m

WORKERS="${WORKERS:-8}"
SLICE="${SLICE:-15}"
TIMEOUT_SECONDS="${TIMEOUT:-25}"
RESULTS_FILE="${RESULTS:-/tmp/stable_scan_results.txt}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${SCRIPT_DIR}/stable_scan_worker.sh"

if [[ ! -x "$WORKER" ]]; then
  echo "Worker script not found/executable: $WORKER" >&2
  exit 1
fi

PATHS=(
  "/home/youruser/synology/Media/Movies"
  "/home/youruser/synology/Media/TV Shows"
  "/home/youruser/synology/Media/Movies - Kids"
  "/home/youruser/synology/Media/TV Shows - Kids"
  "/external/media/Movies"
  "/external/media/TV"
  "/external/media/Kids Movies"
  "/external/media/Kids TV"
)

TMPDIR="/tmp/stable_scan_$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        🧪 STABLE CORRUPTION SCAN (xargs + flock)               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Config:"
echo "  Workers: $WORKERS"
echo "  Sample slice: ${SLICE}s"
echo "  Timeout per sample: ${TIMEOUT_SECONDS}s"
echo "  Results: $RESULTS_FILE"
echo ""

echo "Building file list..."
> "$TMPDIR/filelist.txt"

for p in "${PATHS[@]}"; do
  if [[ -d "$p" ]]; then
    find "$p" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null >> "$TMPDIR/filelist.txt" || true
  fi
done

total_all="$(wc -l < "$TMPDIR/filelist.txt" | tr -d ' ')"
echo "Found $total_all video files across configured paths."

if [[ -f "$RESULTS_FILE" && -s "$RESULTS_FILE" ]]; then
  echo "Resume enabled: filtering already-scanned files..."
  cut -d'|' -f5 "$RESULTS_FILE" > "$TMPDIR/scanned.txt" || true
  # Skip exact matches only
  grep -Fvx -f "$TMPDIR/scanned.txt" "$TMPDIR/filelist.txt" > "$TMPDIR/remaining.txt" || true
else
  cp "$TMPDIR/filelist.txt" "$TMPDIR/remaining.txt"
fi

remaining="$(wc -l < "$TMPDIR/remaining.txt" | tr -d ' ')"
already="$((total_all - remaining))"

echo "To scan now: $remaining (already in results: $already)"
echo ""

if [[ "$remaining" -le 0 ]]; then
  echo "Nothing to do."
  exit 0
fi

echo "Starting scan... (safe to detach screen)"
echo ""

start_ts="$(date +%s)"
printf '%s\n' "$total_all" > "${RESULTS_FILE}.total" 2>/dev/null || true
printf '%s\n' "$start_ts" > "${RESULTS_FILE}.started" 2>/dev/null || true

# Run: one file per worker invocation
cat "$TMPDIR/remaining.txt" | xargs -d '\n' -n 1 -P "$WORKERS" bash -lc \
  "\"$WORKER\" \"${RESULTS_FILE}\" \"${SLICE}\" \"${TIMEOUT_SECONDS}\" \"\$0\"" || true

end_ts="$(date +%s)"
elapsed="$((end_ts - start_ts))"

scanned_now="$(wc -l < "$RESULTS_FILE" 2>/dev/null | tr -d ' ' || echo 0)"
corrupt="$(grep -c '^CORRUPT' "$RESULTS_FILE" 2>/dev/null || echo 0)"
susp="$(grep -c '^SUSPICIOUS' "$RESULTS_FILE" 2>/dev/null || echo 0)"
ok="$((scanned_now - corrupt - susp))"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ SCAN COMPLETE                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Elapsed: $((elapsed/3600))h $(((elapsed%3600)/60))m"
echo "Results lines: $scanned_now"
echo "  OK: $ok"
echo "  SUSPICIOUS: $susp"
echo "  CORRUPT: $corrupt"
echo ""
echo "Tip: view corrupt list:"
echo "  grep '^CORRUPT' \"$RESULTS_FILE\" | head"


