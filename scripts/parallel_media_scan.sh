#!/bin/bash
#
# Parallel Media Integrity Scanner (Optimized)
# Fast corruption detection using 8 parallel workers and smart sampling
#
# Usage: ./parallel_media_scan.sh [start_position] [num_files]
# Example: ./parallel_media_scan.sh 1 50    # Scan files 1-50
#          ./parallel_media_scan.sh 51 50   # Scan files 51-100

set +m

# Arguments
START_POS=${1:-1}
NUM_FILES=${2:-50}

TMPDIR="/tmp/media_scan_$$"
mkdir -p "$TMPDIR"

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
    start=$2
    count=$3

    find /external/media/Movies -type f \( -name "*.mp4" -o -name "*.mkv" \) -printf '%T@ %p\n' 2>/dev/null | \
        sort -rn | tail -n +$start | head -$count | cut -d' ' -f2- | while read -r file; do

        [ -z "$file" ] && continue

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
            grep -c "Invalid NAL" 2>/dev/null || echo "0")

        errors_middle=$(timeout 30 docker run --rm -v "/external/media:/media" linuxserver/ffmpeg:latest \
            -ss $middle -t 180 -i "/media${file#/external/media}" -f null - 2>&1 | \
            grep -c "Invalid NAL" 2>/dev/null || echo "0")

        errors_end=$(timeout 30 docker run --rm -v "/external/media:/media" linuxserver/ffmpeg:latest \
            -sseof -180 -i "/media${file#/external/media}" -f null - 2>&1 | \
            grep -c "Invalid NAL" 2>/dev/null || echo "0")

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
    done
}

# Calculate files per worker
FILES_PER_WORKER=$((NUM_FILES / NUM_WORKERS))
EXTRA=$((NUM_FILES % NUM_WORKERS))

# Start workers
START_TIME=$(date +%s)
PIDS=()

for i in $(seq 1 $NUM_WORKERS); do
    worker_start=$((START_POS + (i - 1) * FILES_PER_WORKER + (i <= EXTRA ? i - 1 : EXTRA)))
    worker_count=$((FILES_PER_WORKER + (i <= EXTRA ? 1 : 0)))
    scan_batch $i $worker_start $worker_count >/dev/null 2>&1 &
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
    echo "║   🔬 Media Scanner - Files $START_POS-$((START_POS+NUM_FILES-1)) (8 Workers)  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                      SCANNING IN PROGRESS                       │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""

    # Progress bar
    filled=$((total * 50 / NUM_FILES))
    empty=$((50 - filled))
    pct=$((total * 100 / NUM_FILES))
    printf "  Progress: ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%% (%d/$NUM_FILES)\n" $pct $total

    printf "  Elapsed: %4ds | ETA: %-15s\n" $elapsed "$eta_str"
    echo ""
    echo "  Workers:"

    # Display workers
    for i in $(seq 1 $NUM_WORKERS); do
        p=$(wc -l < "$TMPDIR/progress_$i.txt" 2>/dev/null | tr -d ' ')
        p=$((p + 1))  # Show 1-based counting
        worker_count=$((FILES_PER_WORKER + (i <= EXTRA ? 1 : 0)))
        c=$(cat "$TMPDIR/current_$i.txt" 2>/dev/null | tr -d '\n')

        if [ -z "$c" ]; then
            printf "  W%d [%d/%d]: %-52s\n" $i $p $worker_count "Ready"
        else
            printf "  W%d [%d/%d]: %-52s\n" $i $p $worker_count "${c:0:52}"
        fi
    done

    echo ""
    echo "  Method: 3 samples × 3 min = ~1 min/file (9 min total)"

    sleep 3
done

wait

clear

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          📊 SCAN COMPLETE - Files $START_POS-$((START_POS+NUM_FILES-1))              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

clean=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^OK" || echo "0")
suspicious=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^SUSPICIOUS" || echo "0")
corrupted=$(cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep -c "^CORRUPT" || echo "0")

echo "  Total: $NUM_FILES files | Time: $(($(date +%s) - START_TIME))s"
echo "  ✅ Clean: $clean | ⚠️  Suspicious: $suspicious | ❌ Corrupted: $corrupted"
echo ""

if [ $corrupted -gt 0 ]; then
    echo "❌ CORRUPTED FILES (MUST RE-DOWNLOAD):"
    cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep "^CORRUPT" | sort -t'|' -k2 -rn | while IFS='|' read -r s e n f; do
        printf "  • %-58s %6s errors\n" "${n:0:58}" "$e"
    done
    echo ""
    echo "  Full paths:"
    cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep "^CORRUPT" | cut -d'|' -f4
    echo ""
fi

if [ $suspicious -gt 0 ]; then
    echo "⚠️  SUSPICIOUS FILES:"
    cat "$TMPDIR"/batch_*.txt 2>/dev/null | grep "^SUSPICIOUS" | sort -t'|' -k2 -rn | while IFS='|' read -r s e n f; do
        printf "  • %-58s %6s errors\n" "${n:0:58}" "$e"
    done
    echo ""
fi

rm -rf "$TMPDIR"
echo "✅ Scan complete!"

