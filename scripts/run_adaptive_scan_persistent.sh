#!/usr/bin/env bash
#
# Wrapper for adaptive corruption scan with persistent storage
# - Saves results to persistent directory (survives reboot)
# - Configures 12 workers for Phase 1, 12 workers for Phase 2 (sequential)
# - Includes performance monitoring
# - Cleans up results files after completion
#
# Usage:
#   ./run_adaptive_scan_persistent.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ADAPTIVE_SCRIPT="${SCRIPT_DIR}/adaptive_corruption_scan.sh"

# Persistent results directory
RESULTS_DIR="${RESULTS_DIR:-/home/youruser/stable_scan/results}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RESULTS_PREFIX="${RESULTS_DIR}/adaptive_scan_${TIMESTAMP}"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Persistent result files (survive reboot)
RESULTS_SAMPLE="${RESULTS_PREFIX}_phase1_sampling.txt"
RESULTS_FULL="${RESULTS_PREFIX}_phase2_fulldecode.txt"
EXISTING_FULL="${RESULTS_DIR}/existing_full_decode.txt" # Optional: reuse from previous runs

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🧭 ADAPTIVE CORRUPTION SCAN (PERSISTENT STORAGE)           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Results directory: $RESULTS_DIR"
echo "Phase 1 results: $RESULTS_SAMPLE"
echo "Phase 2 results: $RESULTS_FULL"
echo ""
echo "Configuration:"
echo "  Phase 1: 12 workers | 20 parts | 10s slices"
echo "  Phase 2: 12 workers | 1800s timeout"
echo "  Max concurrent workers: 12 (phases run sequentially)"
echo ""

# Performance monitoring function
check_performance() {
  local phase="$1"
  echo ""
  echo "=== Performance Check ($phase) ==="
  local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
  local cores=$(nproc)
  local cpu_idle=$(top -bn1 | grep 'Cpu(s)' | awk '{print $8}' | sed 's/%id,//')
  local mem_used=$(free -h | awk '/^Mem:/ {print $3}')
  local mem_total=$(free -h | awk '/^Mem:/ {print $2}')
  local ffmpeg_count=$(pgrep -c ffmpeg 2>/dev/null || echo 0)

  echo "  Load Average: $load (CPU cores: $cores)"
  echo "  CPU Idle: ${cpu_idle}%"
  echo "  Memory: $mem_used / $mem_total"
  echo "  Active ffmpeg: $ffmpeg_count"

  # Warn if load is very high (load > cores * 3)
  local load_threshold=$((cores * 3))
  if [ -n "$load" ] && [ "${load%.*}" -gt "$load_threshold" ] 2>/dev/null; then
    echo "  ⚠️  WARNING: High load average ($load) on $cores-core system"
  fi
}

# Cleanup function (runs on exit or completion)
# DISABLED: User wants to preserve results
cleanup() {
  local exit_code=$?
  echo ""
  echo "=== Scan Complete ==="
  echo "Results preserved at:"
  echo "  Phase 1: $RESULTS_SAMPLE"
  echo "  Phase 2: $RESULTS_FULL"
  exit $exit_code
}

trap cleanup EXIT

# Check initial performance
check_performance "Initial"

# Run Phase 1 with performance check
echo ""
echo "=== Starting Phase 1 (sampling scan) ==="
# Find the largest previous scan (4100+ files) for quality-only mode
PREVIOUS_SCAN=""
PREVIOUS_COUNT=0
for file in "$RESULTS_DIR"/adaptive_scan_*_phase1_sampling.txt; do
  if [[ -f "$file" ]]; then
    count=$(wc -l < "$file" 2>/dev/null | tr -d ' ' || echo "0")
    if [[ "$count" -gt 4000 ]] && [[ "$count" -gt "$PREVIOUS_COUNT" ]]; then
      PREVIOUS_COUNT=$count
      PREVIOUS_SCAN="$file"
    fi
  fi
done
if [[ -n "$PREVIOUS_SCAN" && -f "$PREVIOUS_SCAN" ]]; then
  echo "Using previous scan for quality-only mode: $(basename "$PREVIOUS_SCAN") ($PREVIOUS_COUNT files)"
  export PREVIOUS_RESULTS="$PREVIOUS_SCAN"
fi
WORKERS=12 PARTS=20 SLICE=10 TIMEOUT_SLICE=120 \
WORKERS_FULL=12 TIMEOUT_FULL=1800 \
RESULTS_SAMPLE="$RESULTS_SAMPLE" \
RESULTS_FULL="$RESULTS_FULL" \
EXISTING_FULL_RESULTS="$EXISTING_FULL" \
PREVIOUS_RESULTS="${PREVIOUS_RESULTS:-}" \
ENABLE_SLOW_LANE=1 \
  "$ADAPTIVE_SCRIPT"

# Check performance after Phase 1
check_performance "After Phase 1"

# Phase 2 runs automatically as part of adaptive_script (sequential)
# Performance will be checked at the end via cleanup

echo ""
echo "✅ Adaptive scan complete!"
check_performance "Final"

