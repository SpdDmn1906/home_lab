#!/bin/bash
#
# Media File Integrity Scanner
# Scans video files for playback issues by checking:
# - Video stream corruption (H.264 NAL units, container errors)
# - Codec compatibility issues (HEVC 10-bit, VP9, AV1)
# - Container format problems
# - Suspicious file characteristics
#
# Usage:
#   ./scan_media_integrity.sh [options] [path_to_media_directory]
#
# Options:
#   -q, --quick       Quick scan (faster, less thorough - checks first/last 5 min)
#   -d, --deep        Deep scan (full frame decode validation - SLOW but thorough)
#   -h, --help        Show this help message
#
# Examples:
#   ./scan_media_integrity.sh /external/media/Movies
#   ./scan_media_integrity.sh --quick /external/media/TV
#   ./scan_media_integrity.sh --deep /external/media/Movies/Glory\ Road\ \(2006\)
#
# Default: Quick scan (recommended for large libraries)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SCAN_MODE="quick"  # default
MEDIA_PATH=""

show_help() {
    grep '^#' "$0" | tail -n +3 | head -n -1 | cut -c 3-
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quick)
            SCAN_MODE="quick"
            shift
            ;;
        -d|--deep)
            SCAN_MODE="deep"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            MEDIA_PATH="$1"
            shift
            ;;
    esac
done

# Default path if not provided
MEDIA_PATH="${MEDIA_PATH:-/external/media/Movies}"

LOG_FILE="/tmp/media_integrity_scan_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="/tmp/media_integrity_report_$(date +%Y%m%d_%H%M%S).txt"

echo "🔬 Media File Integrity Scanner" | tee "$REPORT_FILE"
echo "===============================" | tee -a "$REPORT_FILE"
echo "Scan started: $(date)" | tee -a "$REPORT_FILE"
echo "Media path: $MEDIA_PATH" | tee -a "$REPORT_FILE"
echo "Scan mode: $SCAN_MODE" | tee -a "$REPORT_FILE"
if [[ "$SCAN_MODE" == "quick" ]]; then
    echo "  (Quick mode: validates first/last 5 minutes only - faster)" | tee -a "$REPORT_FILE"
else
    echo "  (Deep mode: full frame-by-frame decode - SLOW but thorough)" | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

# Check if ffmpeg/ffprobe is available
if ! command -v ffprobe &> /dev/null; then
    echo -e "${RED}ERROR: ffprobe not found. Please install ffmpeg.${NC}"
    echo "On Ubuntu: sudo apt-get install ffmpeg"
    echo "On macOS: brew install ffmpeg"
    exit 1
fi

# Arrays to store problem files
declare -a CORRUPT_FILES=()
declare -a SUSPICIOUS_FILES=()
declare -a CODEC_ISSUES=()

# Counters
TOTAL_FILES=0
SCANNED_FILES=0
ERROR_FILES=0
SKIPPED_FILES=0

# Validate dependencies
if ! command -v ffprobe &> /dev/null; then
    echo -e "${RED}ERROR: ffprobe not found.${NC}" | tee -a "$REPORT_FILE"
    echo "This script requires ffmpeg. Please install it:" | tee -a "$REPORT_FILE"
    echo "  On Ubuntu: sudo apt-get install ffmpeg" | tee -a "$REPORT_FILE"
    echo "  On macOS: brew install ffmpeg" | tee -a "$REPORT_FILE"
    echo "  Or use Docker: The script will attempt to use linuxserver/ffmpeg container" | tee -a "$REPORT_FILE"

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is also not available. Cannot proceed.${NC}" | tee -a "$REPORT_FILE"
        exit 1
    fi

    echo -e "${YELLOW}Using Docker-based ffmpeg...${NC}" | tee -a "$REPORT_FILE"
    USE_DOCKER=true
else
    USE_DOCKER=false
fi

echo "📊 Scanning media files..." | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Find all video files
while IFS= read -r -d '' file; do
    ((TOTAL_FILES++))

    # Get file info
    filename=$(basename "$file")
    filesize=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)

    echo -n "Scanning [$TOTAL_FILES]: $filename..."

    # Skip very small files (< 10MB, likely trailers/samples)
    if [[ "$filesize" -lt 10485760 ]]; then
        echo -e " ${BLUE}[SKIPPED: too small]${NC}"
        ((SKIPPED_FILES++))
        continue
    fi

    # Validate media file with ffprobe (fast metadata check)
    if [[ "$USE_DOCKER" == true ]]; then
        # Docker-based ffprobe
        ffprobe_cmd="docker run --rm -v $(dirname "$file"):/mnt linuxserver/ffmpeg:latest ffprobe"
        file_arg="/mnt/$(basename "$file")"
    else
        ffprobe_cmd="ffprobe"
        file_arg="$file"
    fi

    if ffprobe_output=$($ffprobe_cmd -v error -show_format -show_streams -of json "$file_arg" 2>&1); then
        ((SCANNED_FILES++))

        # Extract key information
        duration=$(echo "$ffprobe_output" | grep -o '"duration":"[^"]*"' | head -1 | cut -d'"' -f4)
        video_codec=$(echo "$ffprobe_output" | grep -o '"codec_name":"[^"]*"' | head -1 | cut -d'"' -f4)
        format=$(echo "$ffprobe_output" | grep -o '"format_name":"[^"]*"' | cut -d'"' -f4)
        bit_depth=$(echo "$ffprobe_output" | grep -o '"bits_per_raw_sample":"[^"]*"' | head -1 | cut -d'"' -f4)

        # Check for incomplete/corrupted files (no duration)
        if [[ -z "$duration" ]] || [[ "$duration" == "N/A" ]] || [[ "$duration" == "0" ]]; then
            CORRUPT_FILES+=("$file|NO_DURATION|$filesize")
            echo -e " ${RED}⚠️  CORRUPT: No duration found${NC}" | tee -a "$REPORT_FILE"
            ((ERROR_FILES++))
            continue
        fi

        duration_seconds=$(echo "$duration" | cut -d'.' -f1)

        # Now perform stream validation based on scan mode
        if [[ "$SCAN_MODE" == "quick" ]]; then
            # Quick mode: Check first 5 minutes and last 5 minutes
            # This catches most corruption at start/end without full decode
            if [[ "$USE_DOCKER" == true ]]; then
                errors=$(docker run --rm -v $(dirname "$file"):/mnt linuxserver/ffmpeg:latest \
                    -ss 0 -t 300 -i "$file_arg" -f null - 2>&1 | grep -ciE "error|invalid|corrupt" || true)
                errors_end=$(docker run --rm -v $(dirname "$file"):/mnt linuxserver/ffmpeg:latest \
                    -sseof -300 -i "$file_arg" -f null - 2>&1 | grep -ciE "error|invalid|corrupt" || true)
                errors=$((errors + errors_end))
            else
                errors=$(ffmpeg -ss 0 -t 300 -i "$file" -f null - 2>&1 | grep -ciE "error|invalid|corrupt" || true)
                errors_end=$(ffmpeg -sseof -300 -i "$file" -f null - 2>&1 | grep -ciE "error|invalid|corrupt" || true)
                errors=$((errors + errors_end))
            fi
        else
            # Deep mode: Full frame-by-frame decode (SLOW)
            if [[ "$USE_DOCKER" == true ]]; then
                errors=$(docker run --rm -v $(dirname "$file"):/mnt linuxserver/ffmpeg:latest \
                    -v error -i "$file_arg" -f null - 2>&1 | grep -ciE "error|invalid|corrupt" || true)
            else
                errors=$(ffmpeg -v error -i "$file" -f null - 2>&1 | grep -ciE "error|invalid|corrupt" || true)
            fi
        fi

        # Evaluate corruption threshold
        if [[ "$errors" -gt 50 ]]; then
            CORRUPT_FILES+=("$file|VIDEO_STREAM_CORRUPT|$filesize|$errors")
            echo -e " ${RED}⚠️  CORRUPT: $errors video stream errors${NC}" | tee -a "$REPORT_FILE"
            ((ERROR_FILES++))
        elif [[ "$errors" -gt 10 ]]; then
            SUSPICIOUS_FILES+=("$file|DECODE_ERRORS|$filesize|$errors")
            echo -e " ${YELLOW}⚠️  SUSPICIOUS: $errors errors (may cause playback issues)${NC}"
        else
            # File passed stream validation, now check codec compatibility
            codec_warning=""

            # Check for codec compatibility issues with Roku/webOS
            if [[ "$video_codec" == "hevc" ]] && [[ "$bit_depth" == "10" ]]; then
                CODEC_ISSUES+=("$file|HEVC_10BIT|$filesize")
                codec_warning=" ${BLUE}[HEVC 10-bit: may not work on Roku/webOS]${NC}"
            elif [[ "$video_codec" == "vp9" ]] || [[ "$video_codec" == "av1" ]]; then
                CODEC_ISSUES+=("$file|${video_codec^^}|$filesize")
                codec_warning=" ${BLUE}[$video_codec: limited TV support]${NC}"
            fi

            # Check for suspicious file size
            if [[ -n "$duration_seconds" ]] && [[ "$duration_seconds" -gt 3600 ]]; then
                size_mb=$((filesize / 1024 / 1024))
                expected_min_mb=$((duration_seconds * 300 / 3600))

                if [[ "$size_mb" -lt "$expected_min_mb" ]]; then
                    SUSPICIOUS_FILES+=("$file|SMALL_SIZE|$filesize|$duration")
                    codec_warning="${codec_warning} ${YELLOW}[unusually small: ${size_mb}MB]${NC}"
                fi
            fi

            if [[ -n "$codec_warning" ]]; then
                echo -e "$codec_warning"
            else
                echo -e " ${GREEN}✅ OK${NC}"
            fi
        fi

    else
        # ffprobe failed - likely corrupted
        CORRUPT_FILES+=("$file|FFPROBE_FAILED|$filesize")
        echo -e " ${RED}⚠️  CORRUPT: ffprobe failed${NC}" | tee -a "$REPORT_FILE"
        ((ERROR_FILES++))
    fi

done < <(find "$MEDIA_PATH" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.m4v" \) -print0)

# Generate Report
echo "" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "📋 SCAN SUMMARY" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"
echo "Total files found: $TOTAL_FILES" | tee -a "$REPORT_FILE"
echo "Successfully scanned: $SCANNED_FILES" | tee -a "$REPORT_FILE"
echo "Skipped (too small): $SKIPPED_FILES" | tee -a "$REPORT_FILE"
echo "Corrupted files: $ERROR_FILES" | tee -a "$REPORT_FILE"
echo "Suspicious files: ${#SUSPICIOUS_FILES[@]}" | tee -a "$REPORT_FILE"
echo "Codec warnings: ${#CODEC_ISSUES[@]}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Report corrupt files
if [[ ${#CORRUPT_FILES[@]} -gt 0 ]]; then
    echo -e "${RED}🔴 CORRUPT FILES (${#CORRUPT_FILES[@]}):${NC}" | tee -a "$REPORT_FILE"
    echo "These files MUST be re-downloaded:" | tee -a "$REPORT_FILE"
    for item in "${CORRUPT_FILES[@]}"; do
        IFS='|' read -r file reason size <<< "$item"
        echo "  - $(basename "$file") [$reason]" | tee -a "$REPORT_FILE"
        echo "    Path: $file" | tee -a "$REPORT_FILE"
    done
    echo "" | tee -a "$REPORT_FILE"
fi

# Report codec issues
if [[ ${#CODEC_ISSUES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  CODEC COMPATIBILITY ISSUES (${#CODEC_ISSUES[@]}):${NC}" | tee -a "$REPORT_FILE"
    echo "These files may not play on Roku/webOS TVs:" | tee -a "$REPORT_FILE"
    for item in "${CODEC_ISSUES[@]}"; do
        IFS='|' read -r file codec size <<< "$item"
        echo "  - $(basename "$file") [$codec]" | tee -a "$REPORT_FILE"
        echo "    Path: $file" | tee -a "$REPORT_FILE"
    done
    echo "" | tee -a "$REPORT_FILE"
fi

# Report suspicious files
if [[ ${#SUSPICIOUS_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}🟡 SUSPICIOUS FILES (${#SUSPICIOUS_FILES[@]}):${NC}" | tee -a "$REPORT_FILE"
    echo "These files have unusual characteristics:" | tee -a "$REPORT_FILE"
    for item in "${SUSPICIOUS_FILES[@]}"; do
        IFS='|' read -r file reason size duration <<< "$item"
        echo "  - $(basename "$file") [$reason]" | tee -a "$REPORT_FILE"
        echo "    Path: $file" | tee -a "$REPORT_FILE"
    done
    echo "" | tee -a "$REPORT_FILE"
fi


# Recommendations
echo "========================================" | tee -a "$REPORT_FILE"
echo "💡 RECOMMENDATIONS" | tee -a "$REPORT_FILE"
echo "========================================" | tee -a "$REPORT_FILE"

if [[ ${#CORRUPT_FILES[@]} -gt 0 ]]; then
    echo "1. Delete and re-download all CORRUPT files immediately" | tee -a "$REPORT_FILE"
fi

if [[ ${#CODEC_ISSUES[@]} -gt 0 ]]; then
    echo "2. For codec issues:" | tee -a "$REPORT_FILE"
    echo "   - Option A: Force Direct Play in Plex settings (may still fail)" | tee -a "$REPORT_FILE"
    echo "   - Option B: Re-download with H.264 8-bit codec" | tee -a "$REPORT_FILE"
    echo "   - Option C: Use a better client (NVIDIA Shield, Apple TV)" | tee -a "$REPORT_FILE"
fi

echo "3. Run deep scan on suspicious files to confirm:" | tee -a "$REPORT_FILE"
echo "   ./scan_media_integrity.sh --deep /path/to/suspicious/file.mp4" | tee -a "$REPORT_FILE"

echo "4. Prevent future corruption:" | tee -a "$REPORT_FILE"
echo "   - Maintain storage < 90% full at all times" | tee -a "$REPORT_FILE"
echo "   - Enable qBittorrent disk pre-allocation" | tee -a "$REPORT_FILE"
echo "   - Set up automated post-download validation" | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "Full report saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "Detailed log saved to: $LOG_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Scan completed: $(date)" | tee -a "$REPORT_FILE"

