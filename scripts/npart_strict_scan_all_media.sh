#!/usr/bin/env bash
#
# Whole-library STRICT N-part sampling scan (xargs + flock), resumable and screen-safe.
# Enhanced: Skips corruption checks for already-scanned files, only runs quality checks.
#
# Default mode: 20 parts x 10s slices, strict ffmpeg decode (-loglevel error -xerror -sn -dn).
#
# Usage (server):
#   WORKERS=8 PARTS=20 SLICE=10 TIMEOUT=120 RESULTS=/tmp/npart20x10_scan_results.txt \
#   PREVIOUS_RESULTS=/path/to/previous/results.txt \
#   ./npart_strict_scan_all_media.sh
#
set -euo pipefail
set +m

WORKERS="${WORKERS:-8}"
PARTS="${PARTS:-20}"
SLICE="${SLICE:-10}"
TIMEOUT_PER_SLICE="${TIMEOUT:-120}"
RESULTS_FILE="${RESULTS:-/tmp/npart20x10_scan_results.txt}"
SKIP_FULL_DECODE_RESULTS="${SKIP_FULL_DECODE_RESULTS:-}" # optional full-decode results file to skip already-confirmed files
PREVIOUS_RESULTS="${PREVIOUS_RESULTS:-}" # optional previous scan results to skip corruption checks

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${SCRIPT_DIR}/npart_strict_worker_with_quality.sh"

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

TMPDIR="/tmp/npart_strict_scan_$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   ⚡ STRICT N-PART SAMPLING SCAN (RESUMABLE, STABLE, FAST)     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Config:"
echo "  Workers: $WORKERS"
echo "  Parts:   $PARTS"
echo "  Slice:   ${SLICE}s"
echo "  Timeout per slice: ${TIMEOUT_PER_SLICE}s"
echo "  Results: $RESULTS_FILE"
if [[ -n "$SKIP_FULL_DECODE_RESULTS" ]]; then
  echo "  Skip full-decode results: $SKIP_FULL_DECODE_RESULTS"
fi
if [[ -n "$PREVIOUS_RESULTS" ]]; then
  echo "  Previous scan (quality-only mode): $PREVIOUS_RESULTS"
fi
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

mkdir -p "$(dirname "$RESULTS_FILE")" 2>/dev/null || true
touch "$RESULTS_FILE"

# Build list of already-scanned files (for resume)
if [[ -f "$RESULTS_FILE" && -s "$RESULTS_FILE" ]]; then
  echo "Resume enabled: filtering already-scanned files..."
  cut -d'|' -f8 "$RESULTS_FILE" > "$TMPDIR/scanned.txt" || true
  grep -Fvx -f "$TMPDIR/scanned.txt" "$TMPDIR/filelist.txt" > "$TMPDIR/remaining.txt" || true
else
  cp "$TMPDIR/filelist.txt" "$TMPDIR/remaining.txt"
fi

# Optional: skip files already full-decoded in a prior run (so we don't redo work).
if [[ -n "$SKIP_FULL_DECODE_RESULTS" && -f "$SKIP_FULL_DECODE_RESULTS" && -s "$TMPDIR/remaining.txt" ]]; then
  echo "Applying skip-list from full-decode results..."
  cut -d'|' -f5 "$SKIP_FULL_DECODE_RESULTS" > "$TMPDIR/skip_full.txt" || true
  grep -Fvx -f "$TMPDIR/skip_full.txt" "$TMPDIR/remaining.txt" > "$TMPDIR/remaining2.txt" || true
  mv "$TMPDIR/remaining2.txt" "$TMPDIR/remaining.txt"
fi

# NEW: If previous results provided, separate files into:
# - Already scanned (quality-only mode)
# - New files (full corruption + quality check)
if [[ -n "$PREVIOUS_RESULTS" && -f "$PREVIOUS_RESULTS" && -s "$TMPDIR/remaining.txt" ]]; then
  echo "Optimizing: Using previous scan results for quality-only mode..."
  # Extract paths and normalize case (convert /media/ to /Media/ to handle path case differences)
  cut -d'|' -f8 "$PREVIOUS_RESULTS" | sed 's|/home/youruser/synology/media/|/home/youruser/synology/Media/|' > "$TMPDIR/prev_scanned.txt" || true
  # Files in both remaining and previous scan: quality-only mode
  comm -12 <(sort "$TMPDIR/remaining.txt") <(sort "$TMPDIR/prev_scanned.txt") > "$TMPDIR/quality_only.txt" || true
  # Files only in remaining: full check
  comm -23 <(sort "$TMPDIR/remaining.txt") <(sort "$TMPDIR/prev_scanned.txt") > "$TMPDIR/full_check.txt" || true

  quality_only_count="$(wc -l < "$TMPDIR/quality_only.txt" | tr -d ' ' || echo 0)"
  full_check_count="$(wc -l < "$TMPDIR/full_check.txt" | tr -d ' ' || echo 0)"

  echo "  Files for quality-only check (skip corruption): $quality_only_count"
  echo "  Files for full check (corruption + quality): $full_check_count"

  # Process quality-only files first (faster)
  if [[ "$quality_only_count" -gt 0 ]]; then
    echo ""
    echo "Processing quality-only files (fast mode)..."
    cat "$TMPDIR/quality_only.txt" | xargs -d '\n' -I {} -P "$WORKERS" "$WORKER" "$RESULTS_FILE" "$PARTS" "$SLICE" "$TIMEOUT_PER_SLICE" {} "1" || true
  fi

  # Process full-check files
  if [[ "$full_check_count" -gt 0 ]]; then
    echo ""
    echo "Processing new files (full corruption + quality check)..."
    cat "$TMPDIR/full_check.txt" | xargs -d '\n' -I {} -P "$WORKERS" "$WORKER" "$RESULTS_FILE" "$PARTS" "$SLICE" "$TIMEOUT_PER_SLICE" {} "0" || true
  fi
else
  # No previous results: process all files normally (full check)
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

  echo "Starting strict N-part scan... (safe to detach screen)"
  echo ""

  cat "$TMPDIR/remaining.txt" | xargs -d '\n' -n 1 -P "$WORKERS" "$WORKER" "$RESULTS_FILE" "$PARTS" "$SLICE" "$TIMEOUT_PER_SLICE" "0" || true
fi

echo ""
echo "✅ Strict N-part scan complete."

