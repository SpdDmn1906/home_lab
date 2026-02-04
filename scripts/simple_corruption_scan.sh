#!/bin/bash
#
# Simple Sequential Corruption Scan
# Reliable version that actually works
#

set -e

# Media paths
NAS_MOVIES="/home/youruser/synology/Media/Movies"
NAS_TV="/home/youruser/synology/Media/TV Shows"
NAS_KIDS_MOVIES="/home/youruser/synology/Media/Movies - Kids"
USB_MOVIES="/external/media/Movies"
USB_TV="/external/media/TV"
USB_KIDS_MOVIES="/external/media/Kids Movies"

OUTPUT_FILE="/tmp/simple_scan_results.txt"
CORRUPTED_FILE="/tmp/simple_corrupted_files.txt"
SUSPICIOUS_FILE="/tmp/simple_suspicious_files.txt"

: > "$OUTPUT_FILE"
: > "$CORRUPTED_FILE"
: > "$SUSPICIOUS_FILE"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🔬 SIMPLE CORRUPTION SCAN (Sequential)                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Start time: $(date)"
echo ""

# Function to scan a file
scan_file() {
    local file="$1"
    local label="$2"
    local num="$3"
    local total="$4"

    if [ ! -f "$file" ]; then
        return 1
    fi

    filename=$(basename "$file")
    echo "[$num/$total] $label: $filename"

    # Full file pass-through
    scan_output=$(timeout 120 docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
        -v error -i "/media/$filename" -f null - 2>&1 || echo "")

    # Count errors
    errors=$(echo "$scan_output" | grep -ciE "(error|corrupt|invalid|truncated)" 2>/dev/null || echo "0")
    keyframes=$(echo "$scan_output" | grep -ciE "(keyframe|seek error)" 2>/dev/null || echo "0")

    # Get size
    size=$(du -h "$file" 2>/dev/null | cut -f1)

    # Classify
    if [ "$errors" -gt 50 ] || [ "$keyframes" -gt 20 ]; then
        echo "  ❌ CORRUPT ($errors errors, $keyframes keyframe issues)"
        echo "$label|$(basename "$(dirname "$file")")|$filename|$errors|$keyframes|$size" >> "$CORRUPTED_FILE"
    elif [ "$errors" -gt 10 ] || [ "$keyframes" -gt 5 ]; then
        echo "  ⚠️  SUSPICIOUS ($errors errors, $keyframes keyframe issues)"
        echo "$label|$(basename "$(dirname "$file")")|$filename|$errors|$keyframes|$size" >> "$SUSPICIOUS_FILE"
    elif [ "$keyframes" -gt 0 ]; then
        echo "  🔵 FREEZING RISK ($keyframes keyframe issues)"
        echo "$label|$(basename "$(dirname "$file")")|$filename|$errors|$keyframes|$size" >> "$SUSPICIOUS_FILE"
    else
        echo "  ✅ OK"
    fi

    echo "OK|$label|$file" >> "$OUTPUT_FILE"
    return 0
}

# Scan each path
scan_path() {
    local path="$1"
    local label="$2"

    if [ ! -d "$path" ]; then
        echo "⚠️  $label: Path not found"
        return
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Scanning: $label"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Count files
    total=$(find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | wc -l | tr -d ' ')
    echo "Files to scan: $total"
    echo ""

    if [ "$total" -eq 0 ]; then
        echo "No files found"
        echo ""
        return
    fi

    # Scan each file
    num=0
    find "$path" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | while read -r file; do
        num=$((num + 1))
        scan_file "$file" "$label" "$num" "$total"
    done

    echo ""
}

# Scan all paths
scan_path "$NAS_MOVIES" "NAS Movies"
scan_path "$NAS_KIDS_MOVIES" "NAS Kids Movies"
scan_path "$NAS_TV" "NAS TV Shows"
scan_path "$USB_MOVIES" "USB Movies"
scan_path "$USB_KIDS_MOVIES" "USB Kids Movies"
scan_path "$USB_TV" "USB TV Shows"

# Summary
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              📊 SCAN COMPLETE                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "End time: $(date)"
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
    echo "SUSPICIOUS/FREEZING FILES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$SUSPICIOUS_FILE"
fi

echo ""
echo "Results saved to:"
echo "  /tmp/simple_scan_results.txt"
echo "  /tmp/simple_corrupted_files.txt"
echo "  /tmp/simple_suspicious_files.txt"

