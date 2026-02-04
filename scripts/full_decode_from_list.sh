#!/usr/bin/env bash
#
# Full-decode only the files in a provided list (one path per line), resumable.
#
# Usage (server):
#   LIST=/tmp/flagged_files.txt RESULTS=/tmp/full_decode_flagged_results.txt WORKERS=4 TIMEOUT=1800 ./full_decode_from_list.sh
#
set -euo pipefail
set +m

LIST_FILE="${LIST:?LIST (file list) env var required}"
WORKERS="${WORKERS:-4}"
TIMEOUT_SECONDS="${TIMEOUT:-1800}"
RESULTS_FILE="${RESULTS:-/tmp/full_decode_flagged_results.txt}"
EXISTING_FULL_RESULTS="${EXISTING_FULL_RESULTS:-}" # optional: prior full-decode results to skip already-confirmed files

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKER="${SCRIPT_DIR}/full_decode_worker.sh"

if [[ ! -f "$LIST_FILE" ]]; then
  echo "❌ List file not found: $LIST_FILE" >&2
  exit 1
fi
if [[ ! -x "$WORKER" ]]; then
  echo "❌ Worker not executable: $WORKER" >&2
  exit 1
fi

TMPDIR="/tmp/full_decode_list_$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$(dirname "$RESULTS_FILE")" 2>/dev/null || true
touch "$RESULTS_FILE"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         🔎 FULL-DECODE CONFIRM (FLAGGED LIST, RESUMABLE)       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "List:    $LIST_FILE"
echo "Workers: $WORKERS"
echo "Timeout: ${TIMEOUT_SECONDS}s per file"
echo "Results: $RESULTS_FILE"
if [[ -n "$EXISTING_FULL_RESULTS" ]]; then
  echo "Skip existing full results: $EXISTING_FULL_RESULTS"
fi
echo ""

awk 'NF>0{print}' "$LIST_FILE" > "$TMPDIR/list_clean.txt"
TOTAL="$(wc -l < "$TMPDIR/list_clean.txt" | tr -d ' ')"
echo "List entries: $TOTAL"

if [[ -s "$RESULTS_FILE" ]]; then
  echo "Resume enabled: filtering already-confirmed files..."
  cut -d'|' -f5 "$RESULTS_FILE" > "$TMPDIR/confirmed.txt" || true
  grep -Fvx -f "$TMPDIR/confirmed.txt" "$TMPDIR/list_clean.txt" > "$TMPDIR/remaining.txt" || true
else
  cp "$TMPDIR/list_clean.txt" "$TMPDIR/remaining.txt"
fi

# Optional: also skip anything already present in an existing full-decode results file.
if [[ -n "$EXISTING_FULL_RESULTS" && -f "$EXISTING_FULL_RESULTS" && -s "$TMPDIR/remaining.txt" ]]; then
  echo "Applying skip-list from existing full-decode results..."
  cut -d'|' -f5 "$EXISTING_FULL_RESULTS" > "$TMPDIR/skip_existing_full.txt" || true
  grep -Fvx -f "$TMPDIR/skip_existing_full.txt" "$TMPDIR/remaining.txt" > "$TMPDIR/remaining2.txt" || true
  mv "$TMPDIR/remaining2.txt" "$TMPDIR/remaining.txt"
fi

REMAINING="$(wc -l < "$TMPDIR/remaining.txt" | tr -d ' ')"
DONE="$((TOTAL - REMAINING))"
echo "Already done: $DONE | Remaining: $REMAINING"
echo ""

printf '%s\n' "$TOTAL" > "${RESULTS_FILE}.total" 2>/dev/null || true
printf '%s\n' "$(date +%s)" > "${RESULTS_FILE}.started" 2>/dev/null || true

if [[ "$REMAINING" -le 0 ]]; then
  echo "✅ Nothing left to confirm."
  exit 0
fi

echo "Starting full-decode confirm... (safe to detach screen)"
echo ""

cat "$TMPDIR/remaining.txt" | xargs -d '\n' -n 1 -P "$WORKERS" "$WORKER" "$RESULTS_FILE" "$TIMEOUT_SECONDS" || true

echo ""
echo "✅ Full-decode confirm complete."


