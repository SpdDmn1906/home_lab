#!/bin/bash
#
# Comprehensive Media Corruption Scan - PARALLEL VERSION with FREEZING DETECTION
# Scans ALL media paths with full file pass-through to catch freezing issues
#
# Usage: ./comprehensive_corruption_scan_parallel.sh [--background]
#   --background: Run in screen session
#
# Features:
#   - 8 parallel workers for speed
#   - FULL file pass-through (catches freezing/keyframe issues like Lightyear)
#   - Real-time progress with ETA
#   - Estimated time: 6-12 hours (vs 2-4 days)

set +m  # Disable job control for background processes

RUN_BACKGROUND=false
if [ "$1" == "--background" ]; then
    RUN_BACKGROUND=true
fi

# Media paths
NAS_MOVIES="/home/youruser/synology/Media/Movies"
NAS_TV="/home/youruser/synology/Media/TV Shows"
NAS_KIDS_MOVIES="/home/youruser/synology/Media/Movies - Kids"
NAS_KIDS_TV="/home/youruser/synology/Media/TV Shows - Kids"
USB_MOVIES="/external/media/Movies"
USB_TV="/external/media/TV"
USB_KIDS_MOVIES="/external/media/Kids Movies"
USB_KIDS_TV="/external/media/Kids TV Shows"

ALL_PATHS=("$NAS_MOVIES" "$NAS_TV" "$NAS_KIDS_MOVIES" "$NAS_KIDS_TV" "$USB_MOVIES" "$USB_TV" "$USB_KIDS_MOVIES" "$USB_KIDS_TV")
ALL_LABELS=("NAS Movies" "NAS TV" "NAS Kids Movies" "NAS Kids TV" "USB Movies" "USB TV" "USB Kids Movies" "USB Kids TV")

TMPDIR="/tmp/comprehensive_scan_$$"
mkdir -p "$TMPDIR"

OUTPUT_FILE="$TMPDIR/scan_results.txt"
CORRUPTED_FILE="$TMPDIR/corrupted_files.txt"
SUSPICIOUS_FILE="$TMPDIR/suspicious_files.txt"
FREEZING_FILE="$TMPDIR/freezing_files.txt"

: > "$OUTPUT_FILE"
: > "$CORRUPTED_FILE"
: > "$SUSPICIOUS_FILE"
: > "$FREEZING_FILE"

NUM_WORKERS=8
for i in $(seq 1 $NUM_WORKERS); do
    : > "$TMPDIR/progress_$i.txt"
    : > "$TMPDIR/current_$i.txt"
done

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to scan a file with FULL pass-through (catches freezing)
scan_file() {
    local file="$1"
    local relative_path="$2"
    local label="$3"
    local worker_id="$4"

    if [ ! -f "$file" ]; then
        return 1
    fi

    filename=$(basename "$file")

    # FULL file pass-through - decodes entire file (catches freezing/keyframe issues)
    full_scan=$(timeout 300 docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
        -v error -i "/media/$filename" -f null - 2>&1)

    # Count error types
    nal_errors=$(echo "$full_scan" | grep -ciE "(Invalid NAL|invalid nal)" || echo "0")
    decode_errors=$(echo "$full_scan" | grep -ciE "(error decoding|decoding error)" || echo "0")
    corrupt_errors=$(echo "$full_scan" | grep -ciE "corrupt" || echo "0")
    truncated_errors=$(echo "$full_scan" | grep -ciE "truncated" || echo "0")

    # Keyframe issues (cause freezing)
    keyframe_issues=$(echo "$full_scan" | grep -ciE "(missing keyframe|no frame|seek error)" || echo "0")

    # Total errors
    total_errors=$((nal_errors + decode_errors + corrupt_errors + truncated_errors))

    # Get size
    size=$(du -h "$file" 2>/dev/null | cut -f1)

    # Classification
    if [ $total_errors -gt 50 ] || [ $keyframe_issues -gt 20 ]; then
        echo "CORRUPT|$total_errors|$keyframe_issues|$label|$relative_path|$file|$size" >> "$CORRUPTED_FILE"
        echo "CORRUPT|$total_errors|$keyframe_issues|$label|$relative_path|$file|$size" >> "$OUTPUT_FILE"
    elif [ $total_errors -gt 10 ] || [ $keyframe_issues -gt 5 ]; then
        echo "SUSPICIOUS|$total_errors|$keyframe_issues|$label|$relative_path|$file|$size" >> "$SUSPICIOUS_FILE"
        echo "SUSPICIOUS|$total_errors|$keyframe_issues|$label|$relative_path|$file|$size" >> "$OUTPUT_FILE"
    elif [ $keyframe_issues -gt 0 ]; then
        # Freezing risk
        echo "FREEZING_RISK|$total_errors|$keyframe_issues|$label|$relative_path|$file|$size" >> "$FREEZING_FILE"
        echo "FREEZING_RISK|$total_errors|$keyframe_issues|$label|$relative_path|$file|$size" >> "$OUTPUT_FILE"
    else
        echo "OK|$total_errors|$keyframe_issues|$label|$relative_path|$file" >> "$OUTPUT_FILE"
    fi

    echo "." >> "$TMPDIR/progress_$worker_id.txt"
    return 0
}

# Worker function
scan_batch() {
    local worker_id=$1
    local file_list="$2"

    echo "$file_list" | while IFS='|' read -r file label root_dir; do
        [ -z "$file" ] && continue

        filename=$(basename "$file")
        echo "$filename" > "$TMPDIR/current_$worker_id.txt"

        relative_path="${file#$root_dir/}"
        scan_file "$file" "$relative_path" "$label" "$worker_id"

        echo "" > "$TMPDIR/current_$worker_id.txt"
    done
}

# Main scan
run_scan() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║   🔬 COMPREHENSIVE SCAN - PARALLEL with FREEZING DETECTION    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Collecting files from all media paths..."
    echo ""

    ALL_FILES="$TMPDIR/all_files.txt"
    : > "$ALL_FILES"

    total_files=0
    for i in "${!ALL_PATHS[@]}"; do
        path="${ALL_PATHS[$i]}"
        label="${ALL_LABELS[$i]}"

        if [ -d "$path" ]; then
            count=$(find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | wc -l | tr -d ' ')
            echo "  📂 $label: $count files"

            find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | while read -r file; do
                echo "$file|$label|$path" >> "$ALL_FILES"
            done

            total_files=$((total_files + count))
        else
            echo "  ⚠️  $label: Not found"
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total files: $total_files"
    echo "Workers: $NUM_WORKERS parallel"
    echo "Method: FULL file pass-through (catches freezing/keyframe issues)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Split files among workers
    FILES_PER_WORKER=$((total_files / NUM_WORKERS))
    EXTRA=$((total_files % NUM_WORKERS))

    START_TIME=$(date +%s)
    PIDS=()

    for i in $(seq 1 $NUM_WORKERS); do
        worker_start=$(((i - 1) * FILES_PER_WORKER + (i <= EXTRA ? i - 1 : EXTRA) + 1))
        worker_count=$((FILES_PER_WORKER + (i <= EXTRA ? 1 : 0)))

        file_batch=$(tail -n +$worker_start "$ALL_FILES" | head -$worker_count)

        scan_batch $i "$file_batch" >/dev/null 2>&1 &
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
        total=0
        for i in $(seq 1 $NUM_WORKERS); do
            p=$(wc -l < "$TMPDIR/progress_$i.txt" 2>/dev/null | tr -d ' ' || echo "0")
            total=$((total + p))
        done

        elapsed=$(($(date +%s) - START_TIME))

        # ETA
        if [ $total -gt 10 ] && [ $elapsed -gt 30 ]; then
            rate=$(echo "scale=3; $total / $elapsed" | bc 2>/dev/null || echo "0.1")
            remaining=$((total_files - total))
            eta=$(echo "scale=0; $remaining / $rate" | bc 2>/dev/null || echo "0")

            if [ $eta -lt 3600 ]; then
                eta_str="${eta}s"
            elif [ $eta -lt 86400 ]; then
                eta_str="$((eta/3600))h $((eta%3600/60))m"
            else
                eta_str="$((eta/86400))d $((eta%86400/3600))h"
            fi
        else
            eta_str="calculating..."
        fi

        corrupted_count=$(wc -l < "$CORRUPTED_FILE" 2>/dev/null | tr -d ' ' || echo "0")
        suspicious_count=$(wc -l < "$SUSPICIOUS_FILE" 2>/dev/null | tr -d ' ' || echo "0")
        freezing_count=$(wc -l < "$FREEZING_FILE" 2>/dev/null | tr -d ' ' || echo "0")

        clear
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║        🔬 COMPREHENSIVE SCAN IN PROGRESS                      ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""

        # Progress bar
        pct=$((total * 100 / total_files))
        filled=$((pct / 2))
        empty=$((50 - filled))
        printf "  Progress: ["
        printf "%${filled}s" | tr ' ' '█'
        printf "%${empty}s" | tr ' ' '░'
        printf "] %3d%%\n" $pct
        printf "  Files: %d / %d\n" $total $total_files
        printf "  Elapsed: %ds | ETA: %s\n" $elapsed "$eta_str"
        printf "  Rate: %.1f files/min\n" "$(echo "scale=1; $total * 60 / $elapsed" | bc 2>/dev/null || echo "0")"
        echo ""
        echo "  Results:"
        echo "    ${RED}❌ Corrupted: $corrupted_count${NC}"
        echo "    ${YELLOW}⚠️  Suspicious: $suspicious_count${NC}"
        echo "    ${BLUE}🔵 Freezing Risk: $freezing_count${NC}"
        echo ""
        echo "  Workers:"

        for i in $(seq 1 $NUM_WORKERS); do
            p=$(wc -l < "$TMPDIR/progress_$i.txt" 2>/dev/null | tr -d ' ' || echo "0")
            c=$(cat "$TMPDIR/current_$i.txt" 2>/dev/null | head -c 40)
            printf "    W%d [%4d]: %s\n" $i $p "${c:-Idle}"
        done

        sleep 2
    done

    wait
    clear

    total_scanned=$(wc -l < "$OUTPUT_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    corrupted_count=$(wc -l < "$CORRUPTED_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    suspicious_count=$(wc -l < "$SUSPICIOUS_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    freezing_count=$(wc -l < "$FREEZING_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    clean_count=$((total_scanned - corrupted_count - suspicious_count - freezing_count))

    elapsed=$(($(date +%s) - START_TIME))

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              📊 SCAN COMPLETE                                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Total scanned: $total_scanned files"
    echo "  Duration: $((elapsed/3600))h $((elapsed%3600/60))m $((elapsed%60))s"
    echo "  Average: $(echo "scale=1; $total_scanned * 60 / $elapsed" | bc 2>/dev/null || echo "0") files/min"
    echo ""
    echo "  ${GREEN}✅ Clean: $clean_count${NC}"
    echo "  ${YELLOW}⚠️  Suspicious: $suspicious_count${NC}"
    echo "  ${BLUE}🔵 Freezing Risk: $freezing_count${NC}"
    echo "  ${RED}❌ Corrupted: $corrupted_count${NC}"
    echo ""

    if [ $corrupted_count -gt 0 ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔴 CORRUPTED FILES:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$CORRUPTED_FILE" | while IFS='|' read -r status errors keyframes label path file size; do
            echo "  ❌ $label: $(basename "$file")"
            echo "     Errors: $errors | Keyframe Issues: $keyframes | Size: $size"
            echo "     Path: $path"
            echo ""
        done
    fi

    if [ $freezing_count -gt 0 ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔵 FREEZING RISK FILES (Keyframe Issues):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$FREEZING_FILE" | head -20 | while IFS='|' read -r status errors keyframes label path file size; do
            echo "  🔵 $label: $(basename "$file")"
            echo "     Keyframe Issues: $keyframes | Size: $size"
        done
    fi

    # Save results
    cp "$OUTPUT_FILE" /tmp/comprehensive_scan_results.txt
    cp "$CORRUPTED_FILE" /tmp/comprehensive_corrupted_files.txt
    cp "$SUSPICIOUS_FILE" /tmp/comprehensive_suspicious_files.txt
    cp "$FREEZING_FILE" /tmp/comprehensive_freezing_files.txt

    echo ""
    echo "📝 Results saved:"
    echo "   /tmp/comprehensive_scan_results.txt"
    echo "   /tmp/comprehensive_corrupted_files.txt"
    echo "   /tmp/comprehensive_suspicious_files.txt"
    echo "   /tmp/comprehensive_freezing_files.txt (NEW - catches freezing like Lightyear)"
    echo ""

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              ✅ SCAN COMPLETE                                   ║"
    echo "╚════════════════════════════════════════════════════════════════╝"

    rm -rf "$TMPDIR"
}

if [ "$RUN_BACKGROUND" = true ]; then
    echo "Starting parallel scan in background..."
    screen -dmS comprehensive_scan bash -c "$(declare -f run_scan scan_batch scan_file); run_scan; exec bash"
    echo "  ✅ Scan running in: screen -r comprehensive_scan"
else
    run_scan
fi

