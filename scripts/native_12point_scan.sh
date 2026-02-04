#!/bin/bash
#
# Native 12-Point Corruption Scan (NO DOCKER)
# Uses host ffmpeg directly - like our successful previous scans
# 8 parallel workers
#

set +m

TMPDIR="/tmp/native_scan_$$"
mkdir -p "$TMPDIR"

OUTPUT_FILE="/tmp/native_scan_results.txt"
CORRUPTED_FILE="/tmp/native_corrupted.txt"
SUSPICIOUS_FILE="/tmp/native_suspicious.txt"

: > "$OUTPUT_FILE"
: > "$CORRUPTED_FILE"
: > "$SUSPICIOUS_FILE"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🚀 NATIVE 12-POINT SCAN (8 Workers, NO Docker)              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Start time: $(date)"
echo ""

# Scan function using NATIVE ffmpeg
scan_file() {
    local file="$1"
    local worker_id="$2"

    if [ ! -f "$file" ]; then
        return 1
    fi

    filename=$(basename "$file")

    # Get duration using NATIVE ffmpeg
    duration=$(ffmpeg -i "$file" 2>&1 | grep "Duration:" | awk '{print $2}' | tr -d ',' | \
        awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' 2>/dev/null || echo "5400")

    if [ -z "$duration" ] || [ "$duration" = "0" ]; then
        duration=5400
    fi

    # 12 sample points
    total_errors=0
    total_keyframes=0

    for pct in 0 0.08 0.17 0.25 0.33 0.42 0.50 0.58 0.67 0.75 0.83 0.92; do
        offset=$(awk "BEGIN {print int($duration * $pct)}")

        # Sample using NATIVE ffmpeg
        sample_output=$(timeout 35 ffmpeg -ss $offset -i "$file" -t 30 -f null - 2>&1 || echo "")

        errors=$(echo "$sample_output" | grep -ciE "(error|corrupt|invalid|truncated)" 2>/dev/null || echo "0")
        keyframes=$(echo "$sample_output" | grep -ciE "(keyframe|seek error|missing)" 2>/dev/null || echo "0")

        [ -z "$errors" ] && errors=0
        [ -z "$keyframes" ] && keyframes=0

        total_errors=$((total_errors + errors))
        total_keyframes=$((total_keyframes + keyframes))
    done

    # EOF sample
    eof_output=$(timeout 35 ffmpeg -sseof -30 -i "$file" -t 30 -f null - 2>&1 || echo "")

    eof_errors=$(echo "$eof_output" | grep -ciE "(error|corrupt|invalid|truncated)" 2>/dev/null || echo "0")
    eof_keyframes=$(echo "$eof_output" | grep -ciE "(keyframe|seek error)" 2>/dev/null || echo "0")

    [ -z "$eof_errors" ] && eof_errors=0
    [ -z "$eof_keyframes" ] && eof_keyframes=0

    total_errors=$((total_errors + eof_errors))
    total_keyframes=$((total_keyframes + eof_keyframes))

    # Get file info
    size=$(du -h "$file" 2>/dev/null | cut -f1)
    dir_label=$(echo "$file" | grep -oE "(Movies|TV|Kids)" | head -1)

    # Classify
    if [ "$total_errors" -gt 50 ] || [ "$total_keyframes" -gt 20 ]; then
        echo "$dir_label|$filename|$total_errors|$total_keyframes|$size|CORRUPT" >> "$CORRUPTED_FILE"
    elif [ "$total_errors" -gt 10 ] || [ "$total_keyframes" -gt 5 ]; then
        echo "$dir_label|$filename|$total_errors|$total_keyframes|$size|SUSPICIOUS" >> "$SUSPICIOUS_FILE"
    elif [ "$total_keyframes" -gt 0 ]; then
        echo "$dir_label|$filename|$total_errors|$total_keyframes|$size|FREEZING_RISK" >> "$SUSPICIOUS_FILE"
    fi

    echo "OK|$dir_label|$file" >> "$OUTPUT_FILE"
    echo "." >> "$TMPDIR/progress_$worker_id.txt"

    return 0
}

# Worker function
worker() {
    local worker_id=$1
    shift
    local files=("$@")

    for file in "${files[@]}"; do
        [ -z "$file" ] && continue
        scan_file "$file" "$worker_id"
    done
}

# Collect files
echo "Collecting files..."
ALL_FILES=()

paths=(
    "/home/youruser/synology/Media/Movies"
    "/home/youruser/synology/Media/TV Shows"
    "/home/youruser/synology/Media/Movies - Kids"
    "/external/media/Movies"
    "/external/media/TV"
    "/external/media/Kids Movies"
)

for path in "${paths[@]}"; do
    if [ -d "$path" ]; then
        while IFS= read -r -d '' file; do
            ALL_FILES+=("$file")
        done < <(find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -print0 2>/dev/null)
    fi
done

total_files=${#ALL_FILES[@]}
echo "Total files: $total_files"
echo ""

# Initialize progress files
for i in {1..8}; do
    : > "$TMPDIR/progress_$i.txt"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Starting 8 parallel workers..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

START_TIME=$(date +%s)

# Split files among 8 workers
FILES_PER_WORKER=$((total_files / 8))
EXTRA=$((total_files % 8))

PIDS=()
for i in {1..8}; do
    start_idx=$(((i - 1) * FILES_PER_WORKER + (i <= EXTRA ? i - 1 : 0)))
    count=$((FILES_PER_WORKER + (i <= EXTRA ? 1 : 0)))

    worker_files=("${ALL_FILES[@]:$start_idx:$count}")

    worker $i "${worker_files[@]}" &
    PIDS+=($!)
done

# Monitor progress
while true; do
    workers_running=0
    for pid in "${PIDS[@]}"; do
        if ps -p $pid >/dev/null 2>&1; then
            workers_running=1
            break
        fi
    done

    if [ $workers_running -eq 0 ]; then
        break
    fi

    # Calculate progress
    current=0
    for i in {1..8}; do
        p=$(wc -l < "$TMPDIR/progress_$i.txt" 2>/dev/null | tr -d ' ' || echo "0")
        current=$((current + p))
    done

    elapsed=$(($(date +%s) - START_TIME))

    if [ $current -gt 0 ] && [ $elapsed -gt 0 ]; then
        pct=$((current * 100 / total_files))
        rate=$(awk "BEGIN {printf \"%.1f\", $current * 60 / $elapsed}")
        remaining=$((total_files - current))
        eta=$(awk "BEGIN {printf \"%.0f\", $remaining / ($current / $elapsed)}")
        eta_min=$((eta / 60))

        echo "[$(date +%H:%M:%S)] Progress: $current/$total_files ($pct%) | Rate: $rate files/min | ETA: ${eta_min}m"
    fi

    sleep 30
done

wait

ELAPSED=$(($(date +%s) - START_TIME))

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              📊 SCAN COMPLETE                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "End time: $(date)"
echo "Duration: $((ELAPSED / 3600))h $((ELAPSED % 3600 / 60))m $((ELAPSED % 60))s"
echo ""

total=$(wc -l < "$OUTPUT_FILE" 2>/dev/null | tr -d ' ' || echo "0")
corrupted=$(wc -l < "$CORRUPTED_FILE" 2>/dev/null | tr -d ' ' || echo "0")
suspicious=$(wc -l < "$SUSPICIOUS_FILE" 2>/dev/null | tr -d ' ' || echo "0")
clean=$((total - corrupted - suspicious))

echo "Total scanned: $total"
echo "✅ Clean: $clean"
echo "⚠️  Suspicious/Freezing: $suspicious"
echo "❌ Corrupted: $corrupted"
echo ""

if [ "$corrupted" -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CORRUPTED FILES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$CORRUPTED_FILE"
fi

if [ "$suspicious" -gt 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "SUSPICIOUS/FREEZING FILES (first 20):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    head -20 "$SUSPICIOUS_FILE"
fi

echo ""
echo "Results saved:"
echo "  /tmp/native_scan_results.txt"
echo "  /tmp/native_corrupted.txt"
echo "  /tmp/native_suspicious.txt"

rm -rf "$TMPDIR"

