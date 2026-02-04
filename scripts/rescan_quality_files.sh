#!/usr/bin/env bash
#
# Re-scan SUSPICIOUS files with updated quality detection logic
# This will re-process files to see which ones are still flagged after the quality detection update
#
# Usage:
#   PHASE1_RESULTS=/path/to/phase1_results.txt RESULTS=/path/to/rescan_results.txt ./rescan_quality_files.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${SCRIPT_DIR}/npart_strict_worker_with_quality.sh"
PHASE1_RESULTS="${PHASE1_RESULTS:-/home/youruser/stable_scan/results/adaptive_scan_20260111_002353_phase1_sampling.txt}"
RESULTS_FILE="${RESULTS:-/home/youruser/stable_scan/results/quality_rescan_$(date +%Y%m%d_%H%M%S).txt}"
WORKERS="${WORKERS:-12}"

if [[ ! -f "$PHASE1_RESULTS" ]]; then
  echo "❌ Phase 1 results file not found: $PHASE1_RESULTS"
  exit 1
fi

if [[ ! -x "$WORKER" ]]; then
  echo "❌ Worker script not executable: $WORKER"
  exit 1
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🔄 RE-SCAN QUALITY-FLAGGED FILES (UPDATED LOGIC)           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Extract SUSPICIOUS files from Phase 1
TMPDIR="/tmp/rescan_quality_$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Extracting SUSPICIOUS files from Phase 1 results..."
grep "^SUSPICIOUS" "$PHASE1_RESULTS" | awk -F'|' '{print $NF}' > "$TMPDIR/files_to_rescan.txt"

TOTAL=$(wc -l < "$TMPDIR/files_to_rescan.txt" | tr -d ' ')
echo "Files to re-scan: $TOTAL"
echo ""

if [[ "$TOTAL" -eq 0 ]]; then
  echo "No files to re-scan."
  exit 0
fi

mkdir -p "$(dirname "$RESULTS_FILE")" 2>/dev/null || true
touch "$RESULTS_FILE"

echo "Re-scanning with updated quality detection (quality-only mode for speed)..."
echo "Workers: $WORKERS"
echo "Results: $RESULTS_FILE"
echo ""

# Re-scan in quality-only mode (skip corruption checks, just check quality)
cat "$TMPDIR/files_to_rescan.txt" | xargs -d '\n' -I {} -P "$WORKERS" "$WORKER" "$RESULTS_FILE" "20" "10" "120" {} "1" || true

echo ""
echo "✅ Re-scan complete!"
echo "Results: $RESULTS_FILE"

# Summary
ok_count=$(grep -c "^OK" "$RESULTS_FILE" 2>/dev/null || echo 0)
susp_count=$(grep -c "^SUSPICIOUS" "$RESULTS_FILE" 2>/dev/null || echo 0)

echo ""
echo "Summary:"
echo "  OK (no longer flagged): $ok_count"
echo "  SUSPICIOUS (still flagged): $susp_count"
echo ""
echo "Files that are still SUSPICIOUS should be legitimately low quality."

