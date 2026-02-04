#!/bin/bash
#
# Server-Side Media Integrity Scanner
# Runs directly on the media server using Docker-based ffmpeg
#
# Usage: bash scan_media_server.sh [--deep] [path]
#
# Examples:
#   bash scan_media_server.sh /external/media/Movies
#   bash scan_media_server.sh --deep /external/media/Movies/Suspect\ File
#

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
SCAN_MODE="quick"
MEDIA_PATH="/external/media/Movies"

if [[ "${1:-}" == "--deep" ]]; then
    SCAN_MODE="deep"
    shift
fi

if [[ -n "${1:-}" ]]; then
    MEDIA_PATH="$1"
fi

LOG_FILE="/tmp/media_scan_$(date +%Y%m%d_%H%M%S).log"

echo "🔬 Media Integrity Scanner (Server Mode)"
echo "========================================"
echo "Path: $MEDIA_PATH"
echo "Mode: $SCAN_MODE"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker not found${NC}"
    exit 1
fi

# Pull ffmpeg image if not present
if ! docker image inspect linuxserver/ffmpeg:latest &>/dev/null; then
    echo "Pulling ffmpeg Docker image..."
    docker pull linuxserver/ffmpeg:latest
fi

# Counters
total=0
scanned=0
corrupted=0
suspicious=0
codec_warnings=0

# Scan files
find "$MEDIA_PATH" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.m4v" \) -print0 | while IFS= read -r -d '' file; do
    ((total++)) || true
    filename=$(basename "$file")
    filesize=$(stat -c%s "$file" 2>/dev/null)

    # Skip small files
    if [[ "$filesize" -lt 10485760 ]]; then
        continue
    fi

    echo -n "[$total] $filename ... "

    # Get file info
    duration=$(docker run --rm -v "$(dirname "$file"):/mnt" linuxserver/ffmpeg:latest \
        ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 \
        "/mnt/$(basename "$file")" 2>/dev/null || echo "0")

    if [[ "$duration" == "0" ]] || [[ -z "$duration" ]]; then
        echo -e "${RED}CORRUPT (no duration)${NC}" | tee -a "$LOG_FILE"
        ((corrupted++)) || true
        continue
    fi

    # Validate video stream
    if [[ "$SCAN_MODE" == "quick" ]]; then
        # Quick: first + last 5 min
        errors=$(docker run --rm -v "$(dirname "$file"):/mnt" linuxserver/ffmpeg:latest \
            -ss 0 -t 300 -i "/mnt/$(basename "$file")" -f null - 2>&1 | \
            grep -ciE "Invalid NAL|Error splitting|Error submitting|co located POCs" || echo "0")
        errors_end=$(docker run --rm -v "$(dirname "$file"):/mnt" linuxserver/ffmpeg:latest \
            -sseof -300 -i "/mnt/$(basename "$file")" -f null - 2>&1 | \
            grep -ciE "Invalid NAL|Error splitting|Error submitting|co located POCs" || echo "0")
        errors=$((errors + errors_end))
    else
        # Deep: full decode
        errors=$(docker run --rm -v "$(dirname "$file"):/mnt" linuxserver/ffmpeg:latest \
            -v error -i "/mnt/$(basename "$file")" -f null - 2>&1 | \
            grep -ciE "Invalid NAL|Error splitting|Error submitting|co located POCs" || echo "0")
    fi

    # Evaluate
    if [[ "$errors" -gt 50 ]]; then
        echo -e "${RED}CORRUPT ($errors errors)${NC}" | tee -a "$LOG_FILE"
        echo "  File: $file" >> "$LOG_FILE"
        ((corrupted++)) || true
    elif [[ "$errors" -gt 10 ]]; then
        echo -e "${YELLOW}SUSPICIOUS ($errors errors)${NC}" | tee -a "$LOG_FILE"
        echo "  File: $file" >> "$LOG_FILE"
        ((suspicious++)) || true
    else
        echo -e "${GREEN}OK${NC}"
        ((scanned++)) || true
    fi
done

echo ""
echo "========================================"
echo "📊 SCAN RESULTS"
echo "========================================"
echo "Total files: $total"
echo "Clean files: $scanned"
echo "Corrupted: $corrupted"
echo "Suspicious: $suspicious"
echo ""
echo "Full log: $LOG_FILE"

if [[ "$corrupted" -gt 0 ]] || [[ "$suspicious" -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Recommendation: Re-download corrupted files${NC}"
    echo "See log file for full list: $LOG_FILE"
fi

