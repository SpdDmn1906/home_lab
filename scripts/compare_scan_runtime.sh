#!/usr/bin/env bash
#
# Compare throughput and rough runtime estimates between:
# - N-part sampling results (secs=<n> field)
# - full-decode results (secs=<n> field)
#
# Usage:
#   ./compare_scan_runtime.sh /tmp/npart20x10_scan_results.txt /tmp/full_decode_scan_results.txt
#
set -euo pipefail

SAMPLE="${1:-}"
FULL="${2:-}"

if [[ -z "$SAMPLE" || -z "$FULL" ]]; then
  echo "Usage: $0 <sample_results> <full_results>" >&2
  exit 1
fi
if [[ ! -f "$SAMPLE" ]]; then
  echo "Missing sample results: $SAMPLE" >&2
  exit 2
fi
if [[ ! -f "$FULL" ]]; then
  echo "Missing full results: $FULL" >&2
  exit 3
fi

echo "Sample results: $SAMPLE"
echo "Full results:   $FULL"
echo ""

summarize_sample() {
  awk -F'|' '
    function val(k,   i,a){ for(i=1;i<=NF;i++){ split($i,a,"="); if(a[1]==k) return a[2] } return "" }
    NF>=8 {
      status=$1
      secs=val("secs")+0
      n++
      sum+=secs
      if (status=="OK") ok++
      else if (status=="SUSPICIOUS") susp++
      else if (status=="TIMEOUT") tout++
    }
    END{
      if(n==0){print "n=0"; exit}
      printf "lines=%d avg_secs=%.1f ok=%d susp=%d timeout=%d\n", n, sum/n, ok+0, susp+0, tout+0
    }
  ' "$1"
}

summarize_full() {
  awk -F'|' '
    function val(k,   i,a){ for(i=1;i<=NF;i++){ split($i,a,"="); if(a[1]==k) return a[2] } return "" }
    NF>=5 {
      status=$1
      secs=val("secs")+0
      n++
      sum+=secs
      if (status=="OK") ok++
      else if (status=="CORRUPT") bad++
      else if (status=="TIMEOUT") tout++
    }
    END{
      if(n==0){print "n=0"; exit}
      printf "lines=%d avg_secs=%.1f ok=%d corrupt=%d timeout=%d\n", n, sum/n, ok+0, bad+0, tout+0
    }
  ' "$1"
}

echo "=== Sampling summary ==="
summarize_sample "$SAMPLE"
echo ""
echo "=== Full-decode summary ==="
summarize_full "$FULL"
echo ""

echo "Tip: for better estimates, run each scan long enough to have a few hundred lines so avg_secs stabilizes."


