#!/bin/bash
#
# Optimized 11-Point Scan with 12 Workers
# Continues from existing progress if available
#

set +m

TMPDIR="/tmp/optimized_scan_$$"
mkdir -p "$TMPDIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🚀 OPTIMIZED SCAN: 11-Point, 12 Workers                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check for existing progress
RESUME=false
if [ -f /tmp/final_scan_results.txt ]; then
    existing_count=$(wc -l < /tmp/final_scan_results.txt)
    echo "⚠️  Found existing scan results: $existing_count files"
    echo "   Continuing from where we left off..."
    RESUME=true

    # Copy existing results to new location
    cp /tmp/final_scan_results.txt /tmp/optimized_scan_results.txt
    grep "^CORRUPT" /tmp/final_scan_results.txt > /tmp/optimized_corrupted.txt 2>/dev/null || : > /tmp/optimized_corrupted.txt
    grep "^SUSPICIOUS" /tmp/final_scan_results.txt > /tmp/optimized_suspicious.txt 2>/dev/null || : > /tmp/optimized_suspicious.txt
else
    : > /tmp/optimized_scan_results.txt
    : > /tmp/optimized_corrupted.txt
    : > /tmp/optimized_suspicious.txt
fi

echo ""
echo "Building file list..."
> "$TMPDIR/filelist.txt"

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
        find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null >> "$TMPDIR/filelist.txt"
    fi
done

NUM_FILES=$(wc -l < "$TMPDIR/filelist.txt")

# Filter out already scanned files if resuming
if [ "$RESUME" = true ]; then
    echo "Filtering already scanned files..."

    # Extract scanned file paths
    cut -d'|' -f4 /tmp/optimized_scan_results.txt > "$TMPDIR/scanned_files.txt" 2>/dev/null || : > "$TMPDIR/scanned_files.txt"

    # Keep only unscanned files
    grep -Fvxf "$TMPDIR/scanned_files.txt" "$TMPDIR/filelist.txt" > "$TMPDIR/remaining_files.txt" || cp "$TMPDIR/filelist.txt" "$TMPDIR/remaining_files.txt"

    mv "$TMPDIR/remaining_files.txt" "$TMPDIR/filelist.txt"

    REMAINING=$(wc -l < "$TMPDIR/filelist.txt")
    echo "✅ Resuming: $REMAINING files remaining ($(($NUM_FILES - $REMAINING)) already done)"
    NUM_FILES=$REMAINING
fi

echo "✅ Files to scan: $NUM_FILES"
echo ""

# Initialize worker files for 12 workers
NUM_WORKERS=12
for i in $(seq 1 $NUM_WORKERS); do
    : > "$TMPDIR/progress_$i.txt"
    : > "$TMPDIR/batch_$i.txt"
done

# Scan worker function with 11 sample points
scan_batch() {
    batch=$1
    worker_files="$TMPDIR/worker_${batch}_files.txt"

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ ! -f "$file" ] && continue

        filename=$(basename "$file")

        # Get duration
        duration=$(ffmpeg -i "$file" 2>&1 | grep "Duration:" | awk '{print $2}' | tr -d ',' | \
            awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' 2>/dev/null || echo "3600")

        # 11 sample points (every ~9%): 0%, 9%, 18%, 27%, 36%, 45%, 55%, 64%, 73%, 82%, 91%, EOF
        total_err=0

        for pct in 0 0.09 0.18 0.27 0.36 0.45 0.55 0.64 0.73 0.82 0.91; do
            offset=$(echo "$duration * $pct" | bc 2>/dev/null | awk '{print int($1)}')

            errs=$(timeout 35 ffmpeg -ss $offset -i "$file" -t 30 -f null - 2>&1 | \
                grep -c "Invalid NAL\|error\|corrupt\|keyframe" 2>/dev/null || echo "0")

            # Sanitize: strip non-digits (critical for avoiding syntax errors)
            total_err=$((total_err + ${errs//[^0-9]/0}))
        done

        # EOF sample
        errs_eof=$(timeout 35 ffmpeg -sseof -30 -i "$file" -t 30 -f null - 2>&1 | \
            grep -c "Invalid NAL\|error\|corrupt\|keyframe" 2>/dev/null || echo "0")

        total_err=$((total_err + ${errs_eof//[^0-9]/0}))

        # Classify
        if [ $total_err -gt 50 ]; then
            echo "CORRUPT|$total_err|$filename|$file" >> "$TMPDIR/batch_$batch.txt"
        elif [ $total_err -gt 10 ]; then
            echo "SUSPICIOUS|$total_err|$filename|$file" >> "$TMPDIR/batch_$batch.txt"
        else
            echo "OK|$total_err|$filename|$file" >> "$TMPDIR/batch_$batch.txt"
        fi

        echo "." >> "$TMPDIR/progress_$batch.txt"
    done < "$worker_files"
}

# Split files among 12 workers
split_count=$((NUM_FILES / NUM_WORKERS))
extra=$((NUM_FILES % NUM_WORKERS))

for i in $(seq 1 $NUM_WORKERS); do
    start=$(((i - 1) * split_count + (i <= extra ? i - 1 : 0) + 1))
    count=$((split_count + (i <= extra ? 1 : 0)))
    sed -n "${start},$((start + count - 1))p" "$TMPDIR/filelist.txt" > "$TMPDIR/worker_${i}_files.txt"
done

# Start 12 workers
echo "Starting 12 workers with 11-point sampling..."
echo ""

START_TIME=$(date +%s)
PIDS=()

for i in $(seq 1 $NUM_WORKERS); do
    scan_batch $i >/dev/null 2>&1 &
    PIDS+=($!)
done

# Monitor
while ps -p ${PIDS[0]} >/dev/null 2>&1 || ps -p ${PIDS[1]} >/dev/null 2>&1 || ps -p ${PIDS[2]} >/dev/null 2>&1 || \
      ps -p ${PIDS[3]} >/dev/null 2>&1 || ps -p ${PIDS[4]} >/dev/null 2>&1 || ps -p ${PIDS[5]} >/dev/null 2>&1 || \
      ps -p ${PIDS[6]} >/dev/null 2>&1 || ps -p ${PIDS[7]} >/dev/null 2>&1 || ps -p ${PIDS[8]} >/dev/null 2>&1 || \
      ps -p ${PIDS[9]} >/dev/null 2>&1 || ps -p ${PIDS[10]} >/dev/null 2>&1 || ps -p ${PIDS[11]} >/dev/null 2>&1; do

    total=0
    for i in $(seq 1 $NUM_WORKERS); do
        p=$(wc -l < "$TMPDIR/progress_$i.txt" 2>/dev/null | tr -d ' ')
        total=$((total + p))
    done

    elapsed=$(($(date +%s) - START_TIME))

    if [ $total -gt 0 ] && [ $elapsed -gt 10 ]; then
        pct=$((total * 100 / NUM_FILES))
        rate=$(echo "scale=1; $total * 60 / $elapsed" | bc 2>/dev/null || echo "1")
        eta=$(echo "scale=0; ($NUM_FILES - $total) / ($total / $elapsed)" | bc 2>/dev/null || echo "0")
        eta_min=$((eta / 60))

        echo "[$(date +%H:%M:%S)] $total/$NUM_FILES ($pct%) | $rate files/min | ETA: ${eta_min}m"
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
echo "Duration: $((ELAPSED / 3600))h $((ELAPSED % 3600 / 60))m"
echo ""

# Combine results (append to existing)
cat "$TMPDIR"/batch_*.txt >> /tmp/optimized_scan_results.txt 2>/dev/null

total=$(wc -l < /tmp/optimized_scan_results.txt | tr -d ' ')
corrupted=$(grep "^CORRUPT" /tmp/optimized_scan_results.txt | wc -l | tr -d ' ')
suspicious=$(grep "^SUSPICIOUS" /tmp/optimized_scan_results.txt | wc -l | tr -d ' ')
clean=$((total - corrupted - suspicious))

echo "Total: $total"
echo "✅ Clean: $clean"
echo "⚠️  Suspicious: $suspicious"
echo "❌ Corrupted: $corrupted"
echo ""

grep "^CORRUPT" /tmp/optimized_scan_results.txt > /tmp/optimized_corrupted.txt 2>/dev/null
grep "^SUSPICIOUS" /tmp/optimized_scan_results.txt > /tmp/optimized_suspicious.txt 2>/dev/null

[ $corrupted -gt 0 ] && echo "CORRUPTED FILES:" && cat /tmp/optimized_corrupted.txt
[ $suspicious -gt 0 ] && echo "" && echo "SUSPICIOUS (first 20):" && head -20 /tmp/optimized_suspicious.txt

echo ""
echo "Results: /tmp/optimized_scan_results.txt"
echo "         /tmp/optimized_corrupted.txt"
echo "         /tmp/optimized_suspicious.txt"

rm -rf "$TMPDIR"

