#!/bin/bash
#
# High-Priority Media Integrity Scanner
# Scans: Movies, Kids Movies, and downloads folders
# Uses 8 parallel workers with smart sampling
#

set +m

# Target directories
SCAN_DIRS=(
    "/external/media/Movies"
    "/external/media/Kids Movies"
    "/external/media/downloads"
)

TMPDIR="/tmp/media_scan_$$"
mkdir -p "$TMPDIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔬 HIGH-PRIORITY MEDIA SCAN (8 Workers)                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Scanning directories:"
for dir in "${SCAN_DIRS[@]}"; do
    echo "  • $dir"
done
echo ""

# Build file list
echo "📝 Building file list..."
> "$TMPDIR/filelist.txt"

for dir in "${SCAN_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -printf '%T@ %p\n' 2>/dev/null >> "$TMPDIR/filelist.txt"
    fi
done

# Sort by modification time (newest first) and extract paths
sort -rn "$TMPDIR/filelist.txt" | cut -d' ' -f2- > "$TMPDIR/sorted_files.txt"
NUM_FILES=$(wc -l < "$TMPDIR/sorted_files.txt")

echo "✅ Found $NUM_FILES video files"
echo ""
echo "Estimated time: ~$((NUM_FILES * 90 / 8 / 60)) minutes with 8 workers"
echo ""
echo "Starting scan in 5 seconds... (Ctrl+C to cancel)"
sleep 5

# Initialize worker files
NUM_WORKERS=8
for i in $(seq 1 $NUM_WORKERS); do
    : > "$TMPDIR/progress_$i.txt"
    : > "$TMPDIR/batch_$i.txt"
    : > "$TMPDIR/current_$i.txt"
done

# Scan worker function
scan_batch() {
    batch=$1
    worker_files="$TMPDIR/worker_${batch}_files.txt"

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ ! -f "$file" ] && continue

        filename=$(basename "$file")
        echo "$filename" > "$TMPDIR/current_$batch.txt"

        # Get duration for middle calculation
        duration=$(docker run --rm -v "/external/media:/media" linuxserver/ffmpeg:latest \
            -i "/media${file#/external/media}" 2>&1 | grep "Duration:" | awk '{print $2}' | tr -d ',' | \
            awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' 2>/dev/null || echo "3600")

        middle=$(echo "$duration / 2 - 90" | bc 2>/dev/null || echo "1800")

        # Sample 3 sections: beginning, middle, end (3 min each)
        errors_start=$(timeout 30 docker run --rm -v "/external/media:/media" linuxserver/ffmpeg:latest \
            -ss 0 -t 180 -i "/media${file#/external/media}" -f null - 2>&1 | \
            grep -c "Invalid NAL\|error\|corrupt" 2>/dev/null || echo "0")

        errors_middle=$(timeout 30 docker run --rm -v "/external/media:/media" linuxserver/ffmpeg:latest \
            -ss $middle -t 180 -i "/media${file#/external/media}" -f null - 2>&1 | \
            grep -c "Invalid NAL\|error\|corrupt" 2>/dev/null || echo "0")

        errors_end=$(timeout 30 docker run --rm -v "/external/media:/media" linuxserver/ffmpeg:latest \
            -sseof -180 -i "/media${file#/external/media}" -f null - 2>&1 | \
            grep -c "Invalid NAL\|error\|corrupt" 2>/dev/null || echo "0")

        errors=$((${errors_start//[^0-9]/0} + ${errors_middle//[^0-9]/0} + ${errors_end//[^0-9]/0}))

        # Classify
        if [ $errors -gt 50 ]; then
            echo "CORRUPT|$errors|$filename|$file" >> "$TMPDIR/batch_$batch.txt"
        elif [ $errors -gt 10 ]; then
            echo "SUSPICIOUS|$errors|$filename|$file" >> "$TMPDIR/batch_$batch.txt"
        else
            echo "OK|$errors|$filename|$file" >> "$TMPDIR/batch_$batch.txt"
        fi

        echo "." >> "$TMPDIR/progress_$batch.txt"
        echo "" > "$TMPDIR/current_$batch.txt"
    done < "$worker_files"
}

# Split files among workers
split_count=$((NUM_FILES / NUM_WORKERS))
extra=$((NUM_FILES % NUM_WORKERS))

for i in $(seq 1 $NUM_WORKERS); do
    start=$(((i - 1) * split_count + (i <= extra ? i - 1 : 0) + 1))
    count=$((split_count + (i <= extra ? 1 : 0)))
    sed -n "${start},$((start + count - 1))p" "$TMPDIR/sorted_files.txt" > "$TMPDIR/worker_${i}_files.txt"
done

# Start workers
START_TIME=$(date +%s)
PIDS=()

for i in $(seq 1 $NUM_WORKERS); do
    scan_batch $i >/dev/null 2>&1 &
    PIDS+=($!)
done

# ETA tracking
declare -a ETA_SAMPLES=()

# Monitor with watch-style display
while ps -p ${PIDS[0]} >/dev/null 2>&1 || ps -p ${PIDS[1]} >/dev/null 2>&1 || ps -p ${PIDS[2]} >/dev/null 2>&1 || \
      ps -p ${PIDS[3]} >/dev/null 2>&1 || ps -p ${PIDS[4]} >/dev/null 2>&1 || ps -p ${PIDS[5]} >/dev/null 2>&1 || \
      ps -p ${PIDS[6]} >/dev/null 2>&1 || ps -p ${PIDS[7]} >/dev/null 2>&1; do

    total=0
    for i in $(seq 1 $NUM_WORKERS); do
        p=$(wc -l < "$TMPDIR/progress_$i.txt" 2>/dev/null | tr -d ' ')
        total=$((total + p))
    done

    elapsed=$(($(date +%s) - START_TIME))

    # Stable ETA using moving average
    if [ $total -gt 0 ] && [ $elapsed -gt 10 ]; then
        rate=$(echo "scale=3; $total / $elapsed" | bc 2>/dev/null || echo "0.1")
        eta=$(echo "scale=0; ($NUM_FILES - $total) / $rate" | bc 2>/dev/null || echo "0")
        ETA_SAMPLES+=($eta)
        if [ ${#ETA_SAMPLES[@]} -gt 5 ]; then
            ETA_SAMPLES=("${ETA_SAMPLES[@]:1}")
        fi
        sum=0
        for e in "${ETA_SAMPLES[@]}"; do
            sum=$((sum + e))
        done
        avg_eta=$((sum / ${#ETA_SAMPLES[@]}))
        [ $avg_eta -lt 60 ] && eta_str="${avg_eta}s" || eta_str="$((avg_eta/60))m $((avg_eta%60))s"
    else
        eta_str="calculating..."
    fi

    clear

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║   🔬 HIGH-PRIORITY MEDIA SCAN (8 Workers)                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Scanning: Movies, Kids Movies, downloads"
    echo ""

    # Progress bar
    filled=$((total * 60 / NUM_FILES))
    empty=$((60 - filled))
    pct=$((total * 100 / NUM_FILES))
    printf "  Progress: ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%\n" $pct
    printf "  Files: %d / %d | Elapsed: %dm %ds | ETA: %s\n" \
        $total $NUM_FILES $((elapsed/60)) $((elapsed%60)) "$eta_str"
    echo ""

    # Results so far
    clean=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^OK" || echo "0")
    suspicious=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^SUSPICIOUS" || echo "0")
    corrupted=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^CORRUPT" || echo "0")

    echo "  Results so far:"
    printf "    ✅ Clean: %-5d | ⚠️  Suspicious: %-5d | ❌ Corrupt: %-5d\n" $clean $suspicious $corrupted
    echo ""
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Workers:"

    # Display workers
    for i in $(seq 1 $NUM_WORKERS); do
        p=$(wc -l < "$TMPDIR/progress_$i.txt" 2>/dev/null | tr -d ' ')
        worker_total=$(wc -l < "$TMPDIR/worker_${i}_files.txt" 2>/dev/null | tr -d ' ')
        c=$(cat "$TMPDIR/current_$i.txt" 2>/dev/null | tr -d '\n')

        if [ -z "$c" ]; then
            printf "    W%d [%3d/%3d]: Idle\n" $i $p $worker_total
        else
            printf "    W%d [%3d/%3d]: %s\n" $i $p $worker_total "${c:0:45}"
        fi
    done

    echo ""
    echo "  Method: Smart sampling (3 × 3min segments) = ~90s per file"
    echo ""
    echo "  💡 This scan is running in a screen session - safe to detach!"

    sleep 3
done

wait

clear

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          📊 HIGH-PRIORITY SCAN COMPLETE                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

clean=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^OK" || echo "0")
suspicious=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^SUSPICIOUS" || echo "0")
corrupted=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^CORRUPT" || echo "0")

total_time=$(($(date +%s) - START_TIME))
echo "  Total Files: $NUM_FILES | Time: ${total_time}s ($((total_time/60))m)"
echo "  ✅ Clean: $clean | ⚠️  Suspicious: $suspicious | ❌ Corrupted: $corrupted"
echo ""

# Save full report
REPORT_FILE="/tmp/high_priority_scan_report_$(date +%Y%m%d_%H%M%S).txt"
cat "$TMPDIR"/batch_*.txt 2>/dev/null | sort > "$REPORT_FILE"

if [ $corrupted -gt 0 ]; then
    echo "❌ CORRUPTED FILES (MUST DELETE & RE-DOWNLOAD):"
    cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep "^CORRUPT" | sort -t'|' -k2 -rn | while IFS='|' read -r s e n f; do
        printf "  • %-60s (%s errors)\n" "${n}" "$e"
    done
    echo ""
    echo "  Full paths saved to: $REPORT_FILE"
    echo ""
fi

if [ $suspicious -gt 0 ]; then
    echo "⚠️  SUSPICIOUS FILES (May have minor issues):"
    cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep "^SUSPICIOUS" | sort -t'|' -k2 -rn | head -20 | while IFS='|' read -r s e n f; do
        printf "  • %-60s (%s errors)\n" "${n}" "$e"
    done
    [ $suspicious -gt 20 ] && echo "  ... and $((suspicious - 20)) more (see $REPORT_FILE)"
    echo ""
fi

echo "📄 Full report: $REPORT_FILE"
echo ""

# Corruption by directory
echo "📊 Corruption by Directory:"
for dir in "${SCAN_DIRS[@]}"; do
    dir_corrupt=$(grep "^CORRUPT" "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "$dir" || echo "0")
    dir_total=$(grep "$dir" "$TMPDIR"/batch_*.txt 2>/dev/null | wc -l || echo "0")
    if [ $dir_total -gt 0 ]; then
        pct=$((dir_corrupt * 100 / dir_total))
        printf "  %-30s: %d/%d corrupted (%d%%)\n" "$(basename "$dir")" $dir_corrupt $dir_total $pct
    fi
done

echo ""
echo "✅ Scan complete! You can now exit the screen session."
echo "   Press Ctrl+A then D to detach (keeps running)"
echo "   Or type 'exit' to close the screen session"

rm -rf "$TMPDIR"

