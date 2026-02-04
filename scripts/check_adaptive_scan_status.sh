#!/usr/bin/env bash
#
# Status checker for adaptive scan with performance monitoring
# Usage: ./check_adaptive_scan_status.sh
#
set -euo pipefail

RESULTS_DIR="${RESULTS_DIR:-/home/youruser/stable_scan/results}"

# Find latest results files
RESULTS_SAMPLE=$(ls -t "${RESULTS_DIR}"/adaptive_scan_*_phase1_sampling.txt 2>/dev/null | head -1 || echo "")
RESULTS_FULL=$(ls -t "${RESULTS_DIR}"/adaptive_scan_*_phase2_fulldecode.txt 2>/dev/null | head -1 || echo "")

echo "=== Adaptive Scan Status ==="
echo "Results directory: $RESULTS_DIR"
echo ""

# Check screen session
echo "Screen session:"
screen -list | grep adaptive_scan || echo "  No adaptive_scan screen found"

echo ""

# System Performance
echo "=== System Performance ==="
load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
cores=$(nproc)
cpu_idle=$(top -bn1 | grep 'Cpu(s)' | awk '{print $8}' | sed 's/%id,//' || echo "?")
cpu_user=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | sed 's/%us,//' || echo "?")
mem_used=$(free -h | awk '/^Mem:/ {print $3}' 2>/dev/null || echo "?")
mem_total=$(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "?")
mem_pct=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2*100}' 2>/dev/null || echo "?")
ffmpeg_count=$(pgrep -c ffmpeg 2>/dev/null || echo 0)
xargs_count=$(pgrep -c xargs 2>/dev/null || echo 0)

echo "  Load Average: $load (CPU cores: $cores)"
echo "  CPU Usage: ${cpu_user}% user, ${cpu_idle}% idle"
echo "  Memory: $mem_used / $mem_total (${mem_pct}% used)"
echo "  Active ffmpeg: $ffmpeg_count"
echo "  Active xargs: $xargs_count"

# Performance warnings
if [ -n "$load" ] && [ "${load%.*}" -gt "$((cores * 3))" ] 2>/dev/null; then
  echo "  ⚠️  WARNING: High load average ($load) on $cores-core system"
fi
if [ -n "$mem_pct" ] && [ "${mem_pct%.*}" -gt 85 ] 2>/dev/null; then
  echo "  ⚠️  WARNING: High memory usage (${mem_pct}%)"
fi

echo ""

# Phase 1 Status
if [ -n "$RESULTS_SAMPLE" ] && [ -f "$RESULTS_SAMPLE" ]; then
  echo "=== Phase 1 (sampling) ==="
  DONE=$(wc -l < "$RESULTS_SAMPLE" 2>/dev/null | tr -d ' ' || echo 0)
  TOTAL=$(cat "${RESULTS_SAMPLE}.total" 2>/dev/null | tr -d ' ' || echo "?")

  if [ "$TOTAL" != "?" ] && [ "$TOTAL" -gt 0 ] 2>/dev/null; then
    pct=$((DONE*100/TOTAL))
    remaining=$((TOTAL - DONE))
    echo "  Progress: $DONE / $TOTAL (${pct}%)"
    echo "  Remaining: $remaining files"
  else
    echo "  Progress: $DONE files scanned"
    remaining=0
  fi

  read ok susp tout <<<$(awk -F'|' '$1=="OK"{ok++} $1=="SUSPICIOUS"{s++} $1=="TIMEOUT"{t++} END{printf "%d %d %d", ok+0, s+0, t+0}' "$RESULTS_SAMPLE" 2>/dev/null || echo "0 0 0")
  avg=$(awk -F'|' 'BEGIN{sum=0;n=0} {for(i=1;i<=NF;i++){split($i,a,"="); if(a[1]=="secs"){sum+=a[2]+0; n++}}} END{if(n==0) print "?"; else printf "%.1f", sum/n}' "$RESULTS_SAMPLE" 2>/dev/null || echo "?")

  echo "  Status: OK=$ok SUSPICIOUS=$susp TIMEOUT=$tout"
  if [ "$avg" != "?" ]; then
    echo "  Avg time/file: ${avg}s"

    # Calculate ETA (accounting for parallel workers)
    if [ "$remaining" -gt 0 ] && [ "${avg%.*}" -gt 0 ] 2>/dev/null; then
      workers=$ffmpeg_count
      if [ "$workers" -eq 0 ]; then workers=8; fi  # Default to 8 if not detected

      # Total seconds = (remaining files * avg sec/file) / workers
      total_secs=$((remaining * ${avg%.*} / workers))

      # Convert to hours and minutes
      hours=$((total_secs / 3600))
      mins=$(((total_secs % 3600) / 60))

      if [ "$hours" -gt 0 ]; then
        echo "  ETA: ~${hours}h ${mins}m (${workers} workers)"
      elif [ "$mins" -gt 0 ]; then
        echo "  ETA: ~${mins}m (${workers} workers)"
      else
        echo "  ETA: <1m (${workers} workers)"
      fi
    fi
  fi
  echo "  Results file: $RESULTS_SAMPLE"
else
  echo "=== Phase 1 ==="
  echo "  No results file found (scan not started or in progress)"
fi

echo ""

# Phase 2 Status
if [ -n "$RESULTS_FULL" ] && [ -f "$RESULTS_FULL" ]; then
  echo "=== Phase 2 (full-decode confirm) ==="
  full_done=$(wc -l < "$RESULTS_FULL" 2>/dev/null | tr -d ' ' || echo 0)

  # Count flagged files from Phase 1
  if [ -n "$RESULTS_SAMPLE" ] && [ -f "$RESULTS_SAMPLE" ]; then
    flagged_total=$(awk -F'|' '$1!="OK"{print $8}' "$RESULTS_SAMPLE" 2>/dev/null | sort -u | wc -l | tr -d ' ' || echo "?")
    if [ "$flagged_total" != "?" ] && [ "$flagged_total" -gt 0 ] 2>/dev/null; then
      pct=$((full_done*100/flagged_total))
      remaining_phase2=$((flagged_total - full_done))
      echo "  Progress: $full_done / $flagged_total (${pct}%)"
      echo "  Remaining: $remaining_phase2 files"
    else
      echo "  Progress: $full_done files processed"
      remaining_phase2=0
    fi
  else
    echo "  Progress: $full_done files processed"
    remaining_phase2=0
  fi

  read corrupt susp ok timeout <<<$(awk -F'|' '{
    if ($1=="CORRUPT") corrupt++
    else if ($1=="SUSPICIOUS") susp++
    else if ($1=="OK") ok++
    else if ($1=="TIMEOUT") timeout++
  } END {printf "%d %d %d %d", corrupt+0, susp+0, ok+0, timeout+0}' "$RESULTS_FULL" 2>/dev/null || echo "0 0 0 0")

  echo "  Status: CORRUPT=$corrupt SUSPICIOUS=$susp OK=$ok TIMEOUT=$timeout"

  # Calculate Phase 2 ETA
  if [ "$remaining_phase2" -gt 0 ]; then
    # Get average time from Phase 2 results (full-decode is slower)
    avg_phase2=$(awk -F'|' 'BEGIN{sum=0;n=0} {for(i=1;i<=NF;i++){split($i,a,"="); if(a[1]=="secs"){sum+=a[2]+0; n++}}} END{if(n==0) print "?"; else printf "%.1f", sum/n}' "$RESULTS_FULL" 2>/dev/null || echo "?")

    if [ "$avg_phase2" != "?" ] && [ "${avg_phase2%.*}" -gt 0 ] 2>/dev/null; then
      workers_full=$ffmpeg_count
      if [ "$workers_full" -eq 0 ]; then workers_full=8; fi  # Default estimate

      total_secs=$((remaining_phase2 * ${avg_phase2%.*} / workers_full))
      hours=$((total_secs / 3600))
      mins=$(((total_secs % 3600) / 60))

      if [ "$hours" -gt 0 ]; then
        echo "  ETA: ~${hours}h ${mins}m (${workers_full} workers)"
      elif [ "$mins" -gt 0 ]; then
        echo "  ETA: ~${mins}m (${workers_full} workers)"
      else
        echo "  ETA: <1m (${workers_full} workers)"
      fi
    fi
  fi
  echo "  Results file: $RESULTS_FULL"

  echo ""
  echo "  Last 3 results:"
  tail -3 "$RESULTS_FULL" 2>/dev/null | sed 's/^/    /' || echo "    (none)"
else
  echo "=== Phase 2 ==="
  echo "  Not started yet (Phase 1 must complete first)"
fi

echo ""
if [ -n "$RESULTS_SAMPLE" ] && [ -f "$RESULTS_SAMPLE" ]; then
  echo "Last 3 Phase 1 results:"
  tail -3 "$RESULTS_SAMPLE" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
fi

