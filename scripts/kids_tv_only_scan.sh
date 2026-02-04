#!/usr/bin/env bash
#
# Kids TV-only corruption scan (stable, resumable, xargs-based).
# Uses scripts/stable_scan_worker.sh for consistent classification and strict confirm.
#
# Usage (server):
#   RESULTS=/tmp/kids_tv_scan_results.txt WORKERS=8 SLICE=15 TIMEOUT=25 ./kids_tv_only_scan.sh
#
set -euo pipefail
set +m

WORKERS="${WORKERS:-8}"
SLICE="${SLICE:-15}"
TIMEOUT_SECONDS="${TIMEOUT:-25}"
RESULTS_FILE="${RESULTS:-/tmp/kids_tv_scan_results.txt}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${SCRIPT_DIR}/stable_scan_worker.sh"

TARGET="/external/media/Kids TV"

if [[ ! -x "$WORKER" ]]; then
  echo "Worker not executable: $WORKER" >&2
  exit 1
fi
if [[ ! -d "$TARGET" ]]; then
  echo "Target directory missing: $TARGET" >&2
  exit 1
fi

TMPDIR="/tmp/kids_tv_scan_$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║            🧒📺 KIDS TV ONLY SCAN (RESUMABLE)                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Target:  $TARGET"
echo "Results: $RESULTS_FILE"
echo "Workers: $WORKERS | Slice: ${SLICE}s | Timeout: ${TIMEOUT_SECONDS}s"
echo ""

echo "Building file list..."
find "$TARGET" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) 2>/dev/null > "$TMPDIR/filelist.txt"
TOTAL="$(wc -l < "$TMPDIR/filelist.txt" | tr -d ' ')"
echo "Found $TOTAL video files."

if [[ -f "$RESULTS_FILE" && -s "$RESULTS_FILE" ]]; then
  echo "Resume enabled: filtering already-scanned files..."
  cut -d'|' -f5 "$RESULTS_FILE" > "$TMPDIR/scanned.txt" || true
  grep -Fvx -f "$TMPDIR/scanned.txt" "$TMPDIR/filelist.txt" > "$TMPDIR/remaining.txt" || true
else
  cp "$TMPDIR/filelist.txt" "$TMPDIR/remaining.txt"
fi

REMAINING="$(wc -l < "$TMPDIR/remaining.txt" | tr -d ' ')"
DONE="$((TOTAL - REMAINING))"
echo "Already done: $DONE | Remaining: $REMAINING"
echo ""

printf '%s\n' "$TOTAL" > "${RESULTS_FILE}.total" 2>/dev/null || true
printf '%s\n' "$(date +%s)" > "${RESULTS_FILE}.started" 2>/dev/null || true

if [[ "$REMAINING" -le 0 ]]; then
  echo "✅ Nothing left to scan."
  exit 0
fi

echo "Starting scan... (safe to detach screen)"
echo ""

cat "$TMPDIR/remaining.txt" | xargs -d '\n' -n 1 -P "$WORKERS" bash -lc \
  "\"$WORKER\" \"${RESULTS_FILE}\" \"${SLICE}\" \"${TIMEOUT_SECONDS}\" \"\$0\"" || true

echo ""
echo "✅ Kids TV scan complete."


