#!/usr/bin/env bash
#
# Adaptive corruption scan:
#   Phase 1: strict N-part sampling across whole library (fast coverage)
#   Phase 2: full-decode confirm ONLY for flagged items (hits/timeouts) + optional freeze-report list
#
# No deletion/quarantine is performed here — this produces reports only.
#
# Usage (server):
#   WORKERS=8 PARTS=20 SLICE=10 TIMEOUT_SLICE=120 \
#   WORKERS_FULL=4 TIMEOUT_FULL=1800 \
#   RESULTS_SAMPLE=/tmp/npart20x10_scan_results.txt \
#   RESULTS_FULL=/tmp/full_decode_flagged_results.txt \
#   FREEZE_REPORTS=/tmp/freeze_report_paths.txt \
#   ./adaptive_corruption_scan.sh
#
set -euo pipefail
set +m

WORKERS="${WORKERS:-8}"
PARTS="${PARTS:-20}"
SLICE="${SLICE:-10}"
TIMEOUT_SLICE="${TIMEOUT_SLICE:-120}"

WORKERS_FULL="${WORKERS_FULL:-4}"
TIMEOUT_FULL="${TIMEOUT_FULL:-1800}"

RESULTS_SAMPLE="${RESULTS_SAMPLE:-/tmp/npart20x10_scan_results.txt}"
RESULTS_FULL="${RESULTS_FULL:-/tmp/full_decode_flagged_results.txt}"

FREEZE_REPORTS="${FREEZE_REPORTS:-}" # optional file with one path per line
EXISTING_FULL_RESULTS="${EXISTING_FULL_RESULTS:-/tmp/full_decode_scan_results.txt}" # reuse existing full-decode progress if present

# Optional slow-lane for TIMEOUT cases from phase 2:
WORKERS_FULL_SLOW="${WORKERS_FULL_SLOW:-2}"
TIMEOUT_FULL_SLOW="${TIMEOUT_FULL_SLOW:-7200}"
ENABLE_SLOW_LANE="${ENABLE_SLOW_LANE:-1}" # 1=yes, 0=no

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_RUNNER="${SCRIPT_DIR}/npart_strict_scan_all_media.sh"
FULL_FROM_LIST="${SCRIPT_DIR}/full_decode_from_list.sh"

if [[ ! -x "$SAMPLE_RUNNER" ]]; then
  echo "❌ Missing sample runner: $SAMPLE_RUNNER" >&2
  exit 1
fi
if [[ ! -x "$FULL_FROM_LIST" ]]; then
  echo "❌ Missing full-decode list runner: $FULL_FROM_LIST" >&2
  exit 1
fi

TMPDIR="/tmp/adaptive_scan_$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║               🧭 ADAPTIVE CORRUPTION SCAN (2-PHASE)            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Phase 1 (sampling):"
echo "  Workers: $WORKERS | Parts: $PARTS | Slice: ${SLICE}s | Timeout/slice: ${TIMEOUT_SLICE}s"
echo "  Results: $RESULTS_SAMPLE"
echo ""
echo "Phase 2 (full decode confirm flagged):"
echo "  Workers: $WORKERS_FULL | Timeout/file: ${TIMEOUT_FULL}s"
echo "  Results: $RESULTS_FULL"
if [[ -f "$EXISTING_FULL_RESULTS" ]]; then
  echo "  Reuse existing full-decode results (skip): $EXISTING_FULL_RESULTS"
fi
echo ""
if [[ -n "$FREEZE_REPORTS" ]]; then
  echo "Freeze reports list: $FREEZE_REPORTS"
fi
echo ""

echo "=== Phase 1: sampling scan ==="
SKIP_FULL_DECODE_RESULTS=""
if [[ -f "$EXISTING_FULL_RESULTS" ]]; then
  SKIP_FULL_DECODE_RESULTS="$EXISTING_FULL_RESULTS"
fi
# Check for previous scan results to enable quality-only mode for already-scanned files
# If PREVIOUS_RESULTS is explicitly passed, use it (from run script)
# Otherwise, look for largest completed scan (4100+ files)
if [[ -z "${PREVIOUS_RESULTS:-}" ]]; then
  PREVIOUS_RESULTS=""
  RESULTS_DIR="$(dirname "$RESULTS_SAMPLE")"
  # Find largest scan (should be the 4100+ file one)
  PREV_COUNT=0
  PREV=""
  for file in "$RESULTS_DIR"/adaptive_scan_*_phase1_sampling.txt; do
    if [[ -f "$file" ]] && [[ "$file" != "$RESULTS_SAMPLE" ]]; then
      count=$(wc -l < "$file" 2>/dev/null | tr -d ' ' || echo "0")
      if [[ "$count" -gt 4000 ]] && [[ "$count" -gt "$PREV_COUNT" ]]; then
        PREV_COUNT=$count
        PREV="$file"
      fi
    fi
  done
  if [[ -n "$PREV" && -f "$PREV" ]]; then
    PREVIOUS_RESULTS="$PREV"
    echo "Using previous scan for quality-only mode: $(basename "$PREVIOUS_RESULTS") ($PREV_COUNT files)"
  fi
elif [[ -n "$PREVIOUS_RESULTS" && -f "$PREVIOUS_RESULTS" ]]; then
  count=$(wc -l < "$PREVIOUS_RESULTS" 2>/dev/null | tr -d ' ' || echo "0")
  echo "Using specified previous scan for quality-only mode: $(basename "$PREVIOUS_RESULTS") ($count files)"
fi
WORKERS="$WORKERS" PARTS="$PARTS" SLICE="$SLICE" TIMEOUT="$TIMEOUT_SLICE" RESULTS="$RESULTS_SAMPLE" \
SKIP_FULL_DECODE_RESULTS="$SKIP_FULL_DECODE_RESULTS" \
PREVIOUS_RESULTS="$PREVIOUS_RESULTS" \
  "$SAMPLE_RUNNER"

echo ""
echo "Building flagged list from sampling results..."

# Sampling output format:
# STATUS|hits=<n>|timeouts=<n>|secs=<n>|parts=<n>|slice=<n>|base|path
awk -F'|' '
  NF>=8 {
    status=$1
    path=$8
    if (status != "OK") print path
  }
' "$RESULTS_SAMPLE" | sort -u > "$TMPDIR/flagged_from_sampling.txt" || true

echo "Flagged by sampling: $(wc -l < \"$TMPDIR/flagged_from_sampling.txt\" | tr -d \" \")"

# Merge in freeze-report list if provided
if [[ -n "$FREEZE_REPORTS" && -f "$FREEZE_REPORTS" ]]; then
  awk 'NF>0{print}' "$FREEZE_REPORTS" >> "$TMPDIR/flagged_from_sampling.txt"
fi

sort -u "$TMPDIR/flagged_from_sampling.txt" > "$TMPDIR/flagged_final.txt" || true
FLAGGED_TOTAL="$(wc -l < "$TMPDIR/flagged_final.txt" | tr -d ' ')"
echo "Total flagged (including freeze reports): $FLAGGED_TOTAL"

if [[ "$FLAGGED_TOTAL" -le 0 ]]; then
  echo ""
  echo "✅ No flagged files to full-decode confirm."
  exit 0
fi

echo ""
echo "=== Phase 2: full-decode confirm flagged files ==="
LIST="$TMPDIR/flagged_final.txt" WORKERS="$WORKERS_FULL" TIMEOUT="$TIMEOUT_FULL" RESULTS="$RESULTS_FULL" \
EXISTING_FULL_RESULTS="$EXISTING_FULL_RESULTS" \
  "$FULL_FROM_LIST"

if [[ "$ENABLE_SLOW_LANE" == "1" ]]; then
  echo ""
  echo "Collecting TIMEOUTs from phase 2 for slow-lane confirm..."
  awk -F'|' '$1=="TIMEOUT"{print $5}' "$RESULTS_FULL" | sort -u > "$TMPDIR/slow_lane.txt" || true
  slow_n="$(wc -l < "$TMPDIR/slow_lane.txt" | tr -d ' ' || echo 0)"
  echo "Timeout files needing slow-lane: $slow_n"

  if [[ "$slow_n" -gt 0 ]]; then
    echo ""
    echo "=== Phase 2b: slow-lane full-decode confirm (timeouts only) ==="
    LIST="$TMPDIR/slow_lane.txt" WORKERS="$WORKERS_FULL_SLOW" TIMEOUT="$TIMEOUT_FULL_SLOW" RESULTS="$RESULTS_FULL" \
    EXISTING_FULL_RESULTS="$EXISTING_FULL_RESULTS" \
      "$FULL_FROM_LIST"
  fi
fi

echo ""
echo "✅ Adaptive scan complete."


