#!/bin/bash
set -e

OUTPUT="/tmp/working_scan_results.txt"
CORRUPT="/tmp/working_corrupted.txt"
SUSPICIOUS="/tmp/working_suspicious.txt"

: > "$OUTPUT"
: > "$CORRUPT"
: > "$SUSPICIOUS"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔬 WORKING 12-POINT SCAN (Sequential)                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Start: $(date)"
echo ""

scan_file() {
    local file="$1"
    local label="$2"
    local num="$3"
    local total="$4"

    [ ! -f "$file" ] && return

    filename=$(basename "$file")
    echo "[$num/$total] $label: $filename"

    # Get duration
    dur=$(docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
        -i "/media/$filename" 2>&1 | grep "Duration:" | awk '{print $2}' | tr -d ',' | \
        awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' 2>/dev/null || echo "5400")

    # Ensure dur is a number
    if [ -z "$dur" ] || [ "$dur" = "" ]; then
        dur=5400
    fi

    # 12 samples
    errs=0
    keys=0

    for pct in 0 0.08 0.17 0.25 0.33 0.42 0.50 0.58 0.67 0.75 0.83 0.92; do
        # Calculate offset safely
        off=$(awk "BEGIN {print int($dur * $pct)}")

        out=$(timeout 35 docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
            -ss $off -i "/media/$filename" -t 30 -f null - 2>&1 || echo "")

        e=$(echo "$out" | grep -ciE "(error|corrupt|invalid|truncated)" 2>/dev/null || echo "0")
        k=$(echo "$out" | grep -ciE "(keyframe|seek error|missing)" 2>/dev/null || echo "0")

        # Ensure numbers
        [ -z "$e" ] && e=0
        [ -z "$k" ] && k=0

        errs=$((errs + e))
        keys=$((keys + k))
    done

    # EOF
    out=$(timeout 35 docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
        -sseof -30 -i "/media/$filename" -t 30 -f null - 2>&1 || echo "")

    e=$(echo "$out" | grep -ciE "(error|corrupt|invalid|truncated)" 2>/dev/null || echo "0")
    k=$(echo "$out" | grep -ciE "(keyframe|seek error)" 2>/dev/null || echo "0")

    [ -z "$e" ] && e=0
    [ -z "$k" ] && k=0

    errs=$((errs + e))
    keys=$((keys + k))

    sz=$(du -h "$file" 2>/dev/null | cut -f1)

    if [ $errs -gt 50 ] || [ $keys -gt 20 ]; then
        echo "  ❌ CORRUPT ($errs errors, $keys keyframe issues)"
        echo "$label|$filename|$errs|$keys|$sz" >> "$CORRUPT"
    elif [ $errs -gt 10 ] || [ $keys -gt 5 ]; then
        echo "  ⚠️  SUSPICIOUS ($errs errors, $keys keyframe issues)"
        echo "$label|$filename|$errs|$keys|$sz" >> "$SUSPICIOUS"
    elif [ $keys -gt 0 ]; then
        echo "  🔵 FREEZING RISK ($keys keyframe issues)"
        echo "$label|$filename|$errs|$keys|$sz" >> "$SUSPICIOUS"
    else
        echo "  ✅ OK"
    fi

    echo "OK|$label|$file" >> "$OUTPUT"
}

scan_path() {
    local path="$1"
    local label="$2"

    [ ! -d "$path" ] && return

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Scanning: $label"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    total=$(find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | wc -l | tr -d ' ')
    echo "Files: $total"
    echo ""

    num=0
    find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | while read -r file; do
        num=$((num + 1))
        scan_file "$file" "$label" "$num" "$total"
    done

    echo ""
}

scan_path "/home/youruser/synology/Media/Movies" "NAS Movies"
scan_path "/home/youruser/synology/Media/Movies - Kids" "NAS Kids Movies"
scan_path "/home/youruser/synology/Media/TV Shows" "NAS TV Shows"
scan_path "/external/media/Movies" "USB Movies"
scan_path "/external/media/Kids Movies" "USB Kids Movies"
scan_path "/external/media/TV" "USB TV Shows"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              📊 SCAN COMPLETE                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "End: $(date)"
echo ""

total=$(wc -l < "$OUTPUT" 2>/dev/null | tr -d ' ' || echo "0")
corrupt=$(wc -l < "$CORRUPT" 2>/dev/null | tr -d ' ' || echo "0")
suspicious=$(wc -l < "$SUSPICIOUS" 2>/dev/null | tr -d ' ' || echo "0")

echo "Total: $total"
echo "✅ Clean: $((total - corrupt - suspicious))"
echo "⚠️  Suspicious: $suspicious"
echo "❌ Corrupted: $corrupt"
echo ""

[ $corrupt -gt 0 ] && echo "CORRUPTED:" && cat "$CORRUPT"
[ $suspicious -gt 0 ] && echo "" && echo "SUSPICIOUS (first 20):" && head -20 "$SUSPICIOUS"

echo ""
echo "Results: /tmp/working_scan_results.txt"
echo "         /tmp/working_corrupted.txt"
echo "         /tmp/working_suspicious.txt"

