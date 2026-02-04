#!/usr/bin/env bash
#
# Comprehensive FULL-DECODE scan across all media paths (conservative resources).
# - Entire-file decode catches sparse freezing/corruption that sampling can miss (e.g., Gumball case).
# - Resumable: skips files already present in results file.
# - Stable: xargs -P for parallelism + flock for safe appends.
#
# Usage (server):
#   RESULTS=/tmp/full_decode_scan_results.txt WORKERS=2 TIMEOUT=1200 ./full_decode_scan_all_media.sh
#
set -euo pipefail
set +m

WORKERS="${WORKERS:-2}"          # conservative default
TIMEOUT_SECONDS="${TIMEOUT:-1200}"
RESULTS_FILE="${RESULTS:-/tmp/full_decode_scan_results.txt}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${SCRIPT_DIR}/full_decode_worker.sh"

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

TMPDIR="/tmp/full_decode_scan_$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        🔬 FULL-DECODE SCAN (ALL MEDIA PATHS, RESUMABLE)        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Workers: $WORKERS (conservative)"
echo "Per-file timeout: ${TIMEOUT_SECONDS}s"
echo "Results: $RESULTS_FILE"
echo ""

if [[ ! -x "$WORKER" ]]; then
  echo "❌ Worker not executable: $WORKER" >&2
  exit 1
fi

echo "Building file list..."
> "$TMPDIR/filelist.txt"
for p in "${PATHS[@]}"; do
  if [[ -d "$p" ]]; then
    find "$p" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) 2>/dev/null >> "$TMPDIR/filelist.txt" || true
  fi
done

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

mkdir -p "$(dirname "$RESULTS_FILE")" 2>/dev/null || true
touch "$RESULTS_FILE"
printf '%s\n' "$TOTAL" > "${RESULTS_FILE}.total" 2>/dev/null || true
printf '%s\n' "$(date +%s)" > "${RESULTS_FILE}.started" 2>/dev/null || true

if [[ "$REMAINING" -le 0 ]]; then
  echo "✅ Nothing left to scan."
  exit 0
fi

echo "Starting full-decode scan... (safe to detach screen)"
echo ""

cat "$TMPDIR/remaining.txt" | xargs -d '\n' -n 1 -P "$WORKERS" "$WORKER" "$RESULTS_FILE" "$TIMEOUT_SECONDS" || true

echo ""
echo "✅ Full-decode scan complete."


