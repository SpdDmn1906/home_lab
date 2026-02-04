#!/bin/bash
#
# Fast 12-Point Corruption Scan using xargs for parallelization
# Reliable and fast - uses xargs -P for parallel processing
#

set -e

OUTPUT_FILE="/tmp/fast_scan_results.txt"
CORRUPTED_FILE="/tmp/fast_corrupted_files.txt"
SUSPICIOUS_FILE="/tmp/fast_suspicious_files.txt"

: > "$OUTPUT_FILE"
: > "$CORRUPTED_FILE"
: > "$SUSPICIOUS_FILE"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🚀 FAST 12-POINT CORRUPTION SCAN                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Strategy: 12-point sampling with 8 parallel workers (xargs)"
echo "Expected time: 1.5-2 hours"
echo ""
echo "Start time: $(date)"
echo ""

# Create scan function script
cat > /tmp/scan_one_file.sh << 'SCANEOF'
#!/bin/bash
file="$1"
label="$2"

if [ ! -f "$file" ]; then
    exit 0
fi

filename=$(basename "$file")

# Get duration (quick)
duration=$(docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
    -i "/media/$filename" 2>&1 | grep "Duration:" | awk '{print $2}' | tr -d ',' | \
    awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' 2>/dev/null || echo "5400")

if [ -z "$duration" ] || [ "$duration" = "0" ]; then
    duration=5400
fi

# 12 sample points (every ~8%)
total_errors=0
total_keyframes=0

for pct in 0 0.08 0.17 0.25 0.33 0.42 0.50 0.58 0.67 0.75 0.83 0.92; do
    offset=$(echo "$duration * $pct" | bc 2>/dev/null | awk '{print int($1)}')

    output=$(timeout 35 docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
        -ss $offset -i "/media/$filename" -t 30 -f null - 2>&1 || echo "")

    errors=$(echo "$output" | grep -ciE "(error|corrupt|invalid|truncated)" 2>/dev/null || echo "0")
    keyframes=$(echo "$output" | grep -ciE "(keyframe|seek error|missing)" 2>/dev/null || echo "0")

    total_errors=$((total_errors + errors))
    total_keyframes=$((total_keyframes + keyframes))
done

# EOF sample
output=$(timeout 35 docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
    -sseof -30 -i "/media/$filename" -t 30 -f null - 2>&1 || echo "")

eof_errors=$(echo "$output" | grep -ciE "(error|corrupt|invalid|truncated)" 2>/dev/null || echo "0")
eof_keyframes=$(echo "$output" | grep -ciE "(keyframe|seek error)" 2>/dev/null || echo "0")

total_errors=$((total_errors + eof_errors))
total_keyframes=$((total_keyframes + eof_keyframes))

# Get size
size=$(du -h "$file" 2>/dev/null | cut -f1)

# Output result
if [ "$total_errors" -gt 50 ] || [ "$total_keyframes" -gt 20 ]; then
    echo "$label|$filename|$total_errors|$total_keyframes|$size|CORRUPT"
elif [ "$total_errors" -gt 10 ] || [ "$total_keyframes" -gt 5 ]; then
    echo "$label|$filename|$total_errors|$total_keyframes|$size|SUSPICIOUS"
elif [ "$total_keyframes" -gt 0 ]; then
    echo "$label|$filename|$total_errors|$total_keyframes|$size|FREEZING_RISK"
else
    echo "$label|$filename|$total_errors|$total_keyframes|$size|OK"
fi
SCANEOF

chmod +x /tmp/scan_one_file.sh

# Collect all files
echo "Collecting files..."
ALL_FILES="/tmp/all_files_list.txt"
: > "$ALL_FILES"

paths=(
    "/home/youruser/synology/Media/Movies|NAS Movies"
    "/home/youruser/synology/Media/TV Shows|NAS TV"
    "/home/youruser/synology/Media/Movies - Kids|NAS Kids Movies"
    "/external/media/Movies|USB Movies"
    "/external/media/TV|USB TV"
    "/external/media/Kids Movies|USB Kids Movies"
)

total=0
for entry in "${paths[@]}"; do
    path=$(echo "$entry" | cut -d'|' -f1)
    label=$(echo "$entry" | cut -d'|' -f2)

    if [ -d "$path" ]; then
        count=$(find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | wc -l | tr -d ' ')
        echo "  $label: $count files"

        find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | while read -r file; do
            echo "$file|$label"
        done >> "$ALL_FILES"

        total=$((total + count))
    fi
done

echo ""
echo "Total: $total files"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Starting parallel scan with 8 workers..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

START_TIME=$(date +%s)

# Run scan in parallel using xargs
cat "$ALL_FILES" | xargs -P 8 -I {} bash -c '
    file=$(echo "{}" | cut -d"|" -f1)
    label=$(echo "{}" | cut -d"|" -f2)
    result=$(/tmp/scan_one_file.sh "$file" "$label")

    status=$(echo "$result" | cut -d"|" -f6)

    if [ "$status" = "CORRUPT" ]; then
        echo "$result" >> /tmp/fast_corrupted_files.txt
    elif [ "$status" = "SUSPICIOUS" ] || [ "$status" = "FREEZING_RISK" ]; then
        echo "$result" >> /tmp/fast_suspicious_files.txt
    fi

    echo "$result" >> /tmp/fast_scan_results.txt

    # Progress indicator
    count=$(wc -l < /tmp/fast_scan_results.txt 2>/dev/null | tr -d " ")
    if [ $((count % 50)) -eq 0 ]; then
        echo "[$(date +%H:%M:%S)] Progress: $count files scanned"
    fi
'

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
echo "Results saved to:"
echo "  /tmp/fast_scan_results.txt"
echo "  /tmp/fast_corrupted_files.txt"
echo "  /tmp/fast_suspicious_files.txt"

rm -f /tmp/scan_one_file.sh "$ALL_FILES"

