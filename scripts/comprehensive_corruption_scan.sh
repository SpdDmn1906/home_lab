#!/bin/bash
#
# Comprehensive Media Corruption Scan
# Scans ALL media paths on NAS and USB for corruption
#
# Usage: ./comprehensive_corruption_scan.sh [--background]
#   --background: Run in screen session for long-running scan
#
# Paths scanned:
#   - NAS Movies
#   - NAS TV Shows
#   - NAS Kids Movies
#   - NAS Kids TV Shows
#   - USB Movies
#   - USB TV Shows
#   - USB Kids Movies
#   - USB Kids TV Shows

set -e

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

TMPDIR="/tmp/comprehensive_scan_$$"
mkdir -p "$TMPDIR"

OUTPUT_FILE="$TMPDIR/scan_results.txt"
CORRUPTED_FILE="$TMPDIR/corrupted_files.txt"
SUSPICIOUS_FILE="$TMPDIR/suspicious_files.txt"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to scan a file for corruption
scan_file() {
    local file="$1"
    local relative_path="$2"

    if [ ! -f "$file" ]; then
        return 1
    fi

    filename=$(basename "$file")
    echo "[$(date +%H:%M:%S)] Scanning: $filename" > "$TMPDIR/current_file.txt"

    # Get duration
    duration=$(docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
        -i "/media/$(basename "$file")" 2>&1 | grep "Duration:" | awk '{print $2}' | tr -d ',' | \
        awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' 2>/dev/null || echo "3600")

    # Sample 5 sections: start, 25%, 50%, 75%, end (2 min each)
    errors=0

    for offset in 0 0.25 0.5 0.75 "eof"; do
        if [ "$offset" = "eof" ]; then
            # Sample end (last 2 minutes)
            sample_errors=$(timeout 30 docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
                -sseof -120 -i "/media/$(basename "$file")" -t 120 -f null - 2>&1 | \
                grep -cE "(Invalid NAL|error|corrupt|invalid)" 2>/dev/null || echo "0")
        else
            # Calculate offset in seconds
            offset_sec=$(echo "$duration * $offset" | bc 2>/dev/null || echo "0")
            sample_errors=$(timeout 30 docker run --rm -v "$(dirname "$file"):/media" linuxserver/ffmpeg:latest \
                -ss $offset_sec -i "/media/$(basename "$file")" -t 120 -f null - 2>&1 | \
                grep -cE "(Invalid NAL|error|corrupt|invalid)" 2>/dev/null || echo "0")
        fi

        errors=$((errors + sample_errors))
    done

    # Classify
    if [ $errors -gt 50 ]; then
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "CORRUPT|$errors|$relative_path|$file|$size" >> "$CORRUPTED_FILE"
        echo "CORRUPT|$errors|$relative_path|$file|$size" >> "$OUTPUT_FILE"
    elif [ $errors -gt 10 ]; then
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "SUSPICIOUS|$errors|$relative_path|$file|$size" >> "$SUSPICIOUS_FILE"
        echo "SUSPICIOUS|$errors|$relative_path|$file|$size" >> "$OUTPUT_FILE"
    else
        echo "OK|$errors|$relative_path|$file" >> "$OUTPUT_FILE"
    fi

    return 0
}

# Function to scan a directory
scan_directory() {
    local root_dir="$1"
    local label="$2"
    local count=0
    local total=0

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📂 Scanning: $label"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ ! -d "$root_dir" ]; then
        echo "  ⚠️  Directory not found: $root_dir"
        echo ""
        return
    fi

    # Count total files
    total=$(find "$root_dir" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | wc -l | tr -d ' ')
    echo "  Total files to scan: $total"
    echo "  (This may take a while...)"
    echo ""

    # Scan files
    find "$root_dir" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | while read -r file; do
        count=$((count + 1))
        relative_path="${file#$root_dir/}"

        echo "[$count/$total] Scanning: $(basename "$file")"
        scan_file "$file" "$relative_path"

        # Show progress every 10 files
        if [ $((count % 10)) -eq 0 ]; then
            corrupted_count=$(wc -l < "$CORRUPTED_FILE" 2>/dev/null | tr -d ' ' || echo "0")
            suspicious_count=$(wc -l < "$SUSPICIOUS_FILE" 2>/dev/null | tr -d ' ' || echo "0")
            echo "  Progress: $count/$total | Corrupted: $corrupted_count | Suspicious: $suspicious_count"
        fi
    done

    echo "  ✅ Completed: $label"
    echo ""
}

# Main scan function
run_scan() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║      🔬 COMPREHENSIVE MEDIA CORRUPTION SCAN                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Start time: $(date)"
    echo ""

    : > "$OUTPUT_FILE"
    : > "$CORRUPTED_FILE"
    : > "$SUSPICIOUS_FILE"

    # Scan all paths
    scan_directory "$NAS_MOVIES" "NAS Movies"
    scan_directory "$NAS_TV" "NAS TV Shows"
    scan_directory "$NAS_KIDS_MOVIES" "NAS Kids Movies"
    scan_directory "$NAS_KIDS_TV" "NAS Kids TV Shows"
    scan_directory "$USB_MOVIES" "USB Movies"
    scan_directory "$USB_TV" "USB TV Shows"
    scan_directory "$USB_KIDS_MOVIES" "USB Kids Movies"
    scan_directory "$USB_KIDS_TV" "USB Kids TV Shows"

    # Summary
    total_scanned=$(wc -l < "$OUTPUT_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    corrupted_count=$(wc -l < "$CORRUPTED_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    suspicious_count=$(wc -l < "$SUSPICIOUS_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    clean_count=$((total_scanned - corrupted_count - suspicious_count))

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 SCAN SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Total files scanned: $total_scanned"
    echo "  ${GREEN}✅ Clean: $clean_count${NC}"
    echo "  ${YELLOW}⚠️  Suspicious: $suspicious_count${NC}"
    echo "  ${RED}❌ Corrupted: $corrupted_count${NC}"
    echo ""
    echo "End time: $(date)"
    echo ""

    if [ $corrupted_count -gt 0 ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔴 CORRUPTED FILES:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$CORRUPTED_FILE" | while IFS='|' read -r status errors path file size; do
            echo "  ❌ $path"
            echo "     Errors: $errors | Size: $size"
            echo "     File: $file"
            echo ""
        done
    fi

    if [ $suspicious_count -gt 0 ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  SUSPICIOUS FILES:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$SUSPICIOUS_FILE" | head -20 | while IFS='|' read -r status errors path file size; do
            echo "  ⚠️  $path (${errors} errors)"
        done
    fi

    # Save results
    cp "$OUTPUT_FILE" /tmp/comprehensive_scan_results.txt
    cp "$CORRUPTED_FILE" /tmp/comprehensive_corrupted_files.txt
    cp "$SUSPICIOUS_FILE" /tmp/comprehensive_suspicious_files.txt

    echo ""
    echo "📝 Results saved:"
    echo "   /tmp/comprehensive_scan_results.txt"
    echo "   /tmp/comprehensive_corrupted_files.txt"
    echo "   /tmp/comprehensive_suspicious_files.txt"
    echo ""

    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              ✅ COMPREHENSIVE SCAN COMPLETE                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
}

# Run scan
if [ "$RUN_BACKGROUND" = true ]; then
    echo "Starting scan in background (screen session)..."
    screen -dmS comprehensive_scan bash -c "$0; exec bash"
    echo "  ✅ Scan running in screen session: comprehensive_scan"
    echo "  View progress: screen -r comprehensive_scan"
else
    run_scan
fi

