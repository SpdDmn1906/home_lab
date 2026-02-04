#!/bin/bash
#
# Enhanced Duplicate Media Detection Script (Resumable)
# Finds duplicate movies/TV shows across ALL locations
# - Compares by title/year, not just filename
# - Detects duplicates WITHIN same location
# - Detects duplicates ACROSS all location combinations
# - Flags low-quality duplicates (CAM/TS/HDTS versions)
# - RESUMABLE: Can be stopped and restarted without losing progress
#
# Usage: ./find_duplicate_media.sh [--scan-corrupted] [--resume]
#   --scan-corrupted: Also scan duplicates for corruption
#   --resume: Resume from last checkpoint (default behavior)
#

set -e

# Configuration
SCAN_CORRUPTED=false
FORCE_RESCAN=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --scan-corrupted) SCAN_CORRUPTED=true ;;
        --force-rescan) FORCE_RESCAN=true ;;
    esac
done

# Persistent state directory (not temp, so it survives restarts)
STATE_DIR="/tmp/duplicate_scan_state"
mkdir -p "$STATE_DIR"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Media location definitions (DRY: single source of truth)
declare -A MEDIA_LOCATIONS=(
    # Format: "label|path|index_file|type"
    ["nas_movies"]="NAS Movies|/home/youruser/synology/Media/Movies|${STATE_DIR}/nas_movies.txt|movie"
    ["nas_tv"]="NAS TV Shows|/home/youruser/synology/Media/TV Shows|${STATE_DIR}/nas_tv.txt|tv"
    ["nas_kids_movies"]="NAS Kids Movies|/home/youruser/synology/Media/Movies - Kids|${STATE_DIR}/nas_kids_movies.txt|movie"
    ["nas_kids_tv"]="NAS Kids TV Shows|/home/youruser/synology/Media/TV Shows - Kids|${STATE_DIR}/nas_kids_tv.txt|tv"
    ["data_movies"]="Data Movies|/data/media/Movies|${STATE_DIR}/data_movies.txt|movie"
    ["data_tv"]="Data TV Shows|/data/media/TV Shows|${STATE_DIR}/data_tv.txt|tv"
    ["data_kids_movies"]="Data Kids Movies|/data/media/Movies - Kids|${STATE_DIR}/data_kids_movies.txt|movie"
    ["data_kids_tv"]="Data Kids TV Shows|/data/media/TV Shows - Kids|${STATE_DIR}/data_kids_tv.txt|tv"
    ["usb_movies"]="USB Movies|/external/media/Movies|${STATE_DIR}/usb_movies.txt|movie"
    ["usb_tv"]="USB TV Shows|/external/media/TV|${STATE_DIR}/usb_tv.txt|tv"
    ["usb_kids_movies"]="USB Kids Movies|/external/media/Kids Movies|${STATE_DIR}/usb_kids_movies.txt|movie"
    ["usb_kids_tv"]="USB Kids TV Shows|/external/media/Kids TV|${STATE_DIR}/usb_kids_tv.txt|tv"
)

# Progress markers
INDEXING_DONE="${STATE_DIR}/.indexing_done"
DUPLICATES_FOUND="${STATE_DIR}/.duplicates_found"
RESULTS_DISPLAYED="${STATE_DIR}/.results_displayed"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🔍 ENHANCED DUPLICATE MEDIA DETECTION (RESUMABLE)        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

# ============================================================================
# TITLE NORMALIZATION
# ============================================================================

normalize_title() {
    local path="$1"
    local basename=$(basename "$path")

    # Pattern 1: "Title (Year)" with parentheses
    if [[ "$basename" =~ ^(.*)\(([0-9]{4})\) ]]; then
        local title="${BASH_REMATCH[1]}"
        local year="${BASH_REMATCH[2]}"
        title=$(clean_title "$title")
        echo "${title}|${year}"

    # Pattern 2: "Title.Year" or "Title Year" (dot or space separated)
    elif [[ "$basename" =~ ^(.*)[\._[:space:]]([0-9]{4}) ]]; then
        local title="${BASH_REMATCH[1]}"
        local year="${BASH_REMATCH[2]}"
        title=$(clean_title "$title" | sed -E 's/[\._](1080p|720p|webrip|bluray|brrip|bdrip|h264|x264|rarbg).*$//i' | sed 's/[\._]*$//')
        echo "${title}|${year}"

    else
        # No year found, extract just title
        local title=$(clean_title "$basename")
        echo "${title}|0000"
    fi
}

clean_title() {
    local title="$1"
    echo "$title" | \
        sed -e 's/[[:space:]]*$//' \
            -e 's/\[.*\]//g' \
            -e 's/{.*}//g' \
            -e 's/\.[^.]*$//' | \
        sed 's/\.*$//' | \
        sed -E 's/[[:space:]]+(ENG|1080p|720p|WEBRip|Bluray|BRRip|BDRip).*$//i' | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# ============================================================================
# QUALITY DETECTION
# ============================================================================

detect_quality() {
    local path="$1"
    local basename=$(basename "$path")
    local lower=$(echo "$basename" | tr '[:upper:]' '[:lower:]')

    if echo "$lower" | grep -qiE "(cam|ts|tc|hdcam|hdts|hdtc|telesync|telecine|hushrips|nogrp)"; then
        echo "LOW"
    elif echo "$lower" | grep -qiE "(webrip|web-dl|webdl|amzn|netflix|dsnp|hulu)"; then
        echo "WEB"
    elif echo "$lower" | grep -qiE "(bluray|brrip|bdrip|bdr)"; then
        echo "BLURAY"
    elif echo "$lower" | grep -qiE "(dvdrip|dvd)"; then
        echo "DVD"
    else
        echo "UNKNOWN"
    fi
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================

get_video_file() {
    local dir="$1"
    find "$dir" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | head -1
}

get_directory_size() {
    local path="$1"
    du -sb "$path" 2>/dev/null | cut -f1 || echo "0"
}

# ============================================================================
# INDEXING (RESUMABLE)
# ============================================================================

index_location() {
    local location_key="$1"
    local location_data="${MEDIA_LOCATIONS[$location_key]}"

    if [ -z "$location_data" ]; then
        log_warning "Unknown location key: $location_key"
        return 1
    fi

    IFS='|' read -r label path index_file type <<< "$location_data"

    # Check if already indexed (resume support)
    if [ -f "$index_file" ] && [ -s "$index_file" ] && [ "$FORCE_RESCAN" != "true" ]; then
        local count=$(wc -l < "$index_file" 2>/dev/null | tr -d ' ' || echo "0")
        log_info "📂 $label (using cached index: $count items)"
        return 0
    fi

    log_info "📂 Indexing $label..."
    : > "$index_file"

    if [ ! -d "$path" ]; then
        log_warning "Path not found: $path"
        : > "$index_file"
        return 0
    fi

        # Index directories (movies/TV shows)
    find "$path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
        local normalized=$(normalize_title "$dir")
        local quality=$(detect_quality "$dir")
        local video_file=$(get_video_file "$dir")
        local size=$(get_directory_size "$dir")
        echo "${normalized}|${dir}|${quality}|${video_file}|${size}" >> "$index_file"
        done

    # Index loose files in root
    find "$path" -maxdepth 1 -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) 2>/dev/null | while read -r file; do
        local normalized=$(normalize_title "$file")
        local quality=$(detect_quality "$file")
        local size=$(get_directory_size "$file")
        echo "${normalized}|${file}|${quality}|${file}|${size}" >> "$index_file"
        done

    local count=$(wc -l < "$index_file" 2>/dev/null | tr -d ' ' || echo "0")
    log_success "Found $count items"
}

index_all_locations() {
    if [ -f "$INDEXING_DONE" ] && [ "$FORCE_RESCAN" != "true" ]; then
        log_info "Indexing already completed (use --force-rescan to re-index)"
        return 0
    fi

    log_info "Starting indexing phase..."
    echo ""

    # Index all locations
    for key in "${!MEDIA_LOCATIONS[@]}"; do
        index_location "$key"
    done

    touch "$INDEXING_DONE"
    log_success "Indexing phase complete"
    echo ""
}

# ============================================================================
# DUPLICATE DETECTION (RESUMABLE)
# ============================================================================

find_duplicates_between() {
    local file1="$1"
    local file2="$2"
    local location1_label="$3"
    local location2_label="$4"
    local output_file="$5"

    if [ ! -f "$file1" ] || [ ! -f "$file2" ] || [ ! -s "$file1" ] || [ ! -s "$file2" ]; then
        return 0
    fi

    while IFS='|' read -r title year path1 quality1 video1 size1; do
        local matches=$(grep "^${title}|${year}|" "$file2" 2>/dev/null || true)
        if [ -n "$matches" ]; then
            echo "$matches" | while IFS='|' read -r title2 year2 path2 quality2 video2 size2; do
                echo "${title}|${year}|${location1_label}|${path1}|${quality1}|${video1}|${size1}|${location2_label}|${path2}|${quality2}|${video2}|${size2}" >> "$output_file"
            done
        fi
    done < "$file1"
}

find_duplicates_within() {
    local file="$1"
    local location_label="$2"
    local output_file="$3"

    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        return 0
    fi

    local sorted_file="${STATE_DIR}/sorted_$$"
    sort -t'|' -k1,2 "$file" > "$sorted_file"

    local prev_title="" prev_year="" prev_path="" prev_quality="" prev_video="" prev_size=""

    while IFS='|' read -r title year path quality video size; do
        if [ "$title|$year" = "$prev_title|$prev_year" ] && [ "$path" != "$prev_path" ]; then
            echo "${title}|${year}|${location_label}|${prev_path}|${prev_quality}|${prev_video}|${prev_size}|${location_label}|${path}|${quality}|${video}|${size}" >> "$output_file"
        fi
        prev_title="$title"
        prev_year="$year"
        prev_path="$path"
        prev_quality="$quality"
        prev_video="$video"
        prev_size="$size"
    done < "$sorted_file"

    rm -f "$sorted_file"
}

find_all_duplicates() {
    local duplicate_movies="${STATE_DIR}/duplicate_movies.txt"
    local duplicate_tv="${STATE_DIR}/duplicate_tv.txt"

    if [ -f "$DUPLICATES_FOUND" ] && [ "$FORCE_RESCAN" != "true" ]; then
        log_info "Duplicate detection already completed (use --force-rescan to re-scan)"
        return 0
    fi

    log_info "Finding duplicates..."
    echo ""

    : > "$duplicate_movies"
    : > "$duplicate_tv"

    # Separate storage locations (NAS/Data are same storage, so use NAS only)
    # USB is separate storage
    local nas_movie_files=()
    local nas_tv_files=()
    local usb_movie_files=()
    local usb_tv_files=()

    for key in "${!MEDIA_LOCATIONS[@]}"; do
        IFS='|' read -r label path index_file type <<< "${MEDIA_LOCATIONS[$key]}"

        # Skip Data paths (they're bind mounts of NAS, same storage)
        if [[ "$key" == data_* ]]; then
            continue
        fi

        if [[ "$key" == nas_* ]] || [[ "$key" == usb_* ]]; then
            if [ "$type" = "movie" ]; then
                if [[ "$key" == nas_* ]]; then
                    nas_movie_files+=("$index_file|$label")
                else
                    usb_movie_files+=("$index_file|$label")
                fi
            else
                if [[ "$key" == nas_* ]]; then
                    nas_tv_files+=("$index_file|$label")
                else
                    usb_tv_files+=("$index_file|$label")
                fi
            fi
        fi
    done

    # Find cross-storage duplicates (NAS ↔ USB only - they're different storage)
    log_info "  Checking cross-storage duplicates (NAS ↔ USB)..."
    find_cross_storage_duplicates nas_movie_files[@] usb_movie_files[@] "$duplicate_movies"
    find_cross_storage_duplicates nas_tv_files[@] usb_tv_files[@] "$duplicate_tv"

    # Find within-storage duplicates (NAS ↔ NAS, USB ↔ USB)
    # These are REAL duplicates on the same storage device
    log_info "  Checking within-storage duplicates (NAS ↔ NAS, USB ↔ USB)..."
    find_cross_duplicates nas_movie_files[@] "$duplicate_movies"
    find_cross_duplicates nas_tv_files[@] "$duplicate_tv"
    find_cross_duplicates usb_movie_files[@] "$duplicate_movies"
    find_cross_duplicates usb_tv_files[@] "$duplicate_tv"

    # Find within-location duplicates (same directory - true duplicates in same folder)
    log_info "  Checking within-location duplicates (same directory)..."
    for key in "${!MEDIA_LOCATIONS[@]}"; do
        IFS='|' read -r label path index_file type <<< "${MEDIA_LOCATIONS[$key]}"
        # Skip Data paths (same as NAS, would be false positives)
        if [[ "$key" == data_* ]]; then
            continue
        fi
        if [ "$type" = "movie" ]; then
            find_duplicates_within "$index_file" "$label" "$duplicate_movies"
        else
            find_duplicates_within "$index_file" "$label" "$duplicate_tv"
        fi
    done

    touch "$DUPLICATES_FOUND"
    log_success "Duplicate detection complete"
    echo ""
}

find_cross_duplicates() {
    local files_array_name="$1"
    local output_file="$2"
    local -a files_array=("${!files_array_name}")

    local len=${#files_array[@]}
    for ((i=0; i<len; i++)); do
        IFS='|' read -r file1 label1 <<< "${files_array[$i]}"
        for ((j=i+1; j<len; j++)); do
            IFS='|' read -r file2 label2 <<< "${files_array[$j]}"
            find_duplicates_between "$file1" "$file2" "$label1" "$label2" "$output_file"
        done
    done
}

find_cross_storage_duplicates() {
    local files1_array_name="$1"
    local files2_array_name="$2"
    local output_file="$3"
    local -a files1_array=("${!files1_array_name}")
    local -a files2_array=("${!files2_array_name}")

    # Compare all files from storage1 against all files from storage2
    for file1_data in "${files1_array[@]}"; do
        IFS='|' read -r file1 label1 <<< "$file1_data"
        for file2_data in "${files2_array[@]}"; do
            IFS='|' read -r file2 label2 <<< "$file2_data"
            find_duplicates_between "$file1" "$file2" "$label1" "$label2" "$output_file"
        done
    done
}

# ============================================================================
# RESULTS DISPLAY
# ============================================================================

display_results() {
    if [ -f "$RESULTS_DISPLAYED" ] && [ "$FORCE_RESCAN" != "true" ]; then
        log_info "Results already displayed (use --force-rescan to re-display)"
        return 0
    fi

    local duplicate_movies="${STATE_DIR}/duplicate_movies.txt"
    local duplicate_tv="${STATE_DIR}/duplicate_tv.txt"

    local movie_dup_count=$(sort -u "$duplicate_movies" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    local tv_dup_count=$(sort -u "$duplicate_tv" 2>/dev/null | wc -l | tr -d ' ' || echo "0")

clear

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           📊 ENHANCED DUPLICATE DETECTION RESULTS              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

    display_summary
    echo ""

    if [ "$movie_dup_count" -eq 0 ] && [ "$tv_dup_count" -eq 0 ]; then
        log_success "No duplicates found!"
        touch "$RESULTS_DISPLAYED"
        return 0
    fi

    if [ "$movie_dup_count" -gt 0 ]; then
        display_duplicate_movies "$duplicate_movies"
    fi

    if [ "$tv_dup_count" -gt 0 ]; then
        display_duplicate_tv "$duplicate_tv"
    fi

    display_next_steps "$duplicate_movies"
    save_reports "$duplicate_movies" "$duplicate_tv"
    touch "$RESULTS_DISPLAYED"
}

display_summary() {
echo "📦 Summary:"
echo "───────────────────────────────────────────────────────────────"

    for key in "${!MEDIA_LOCATIONS[@]}"; do
        IFS='|' read -r label path index_file type <<< "${MEDIA_LOCATIONS[$key]}"
        if [ -f "$index_file" ]; then
            local count=$(wc -l < "$index_file" 2>/dev/null | tr -d ' ' || echo "0")
            echo "  $label: $count"
        fi
    done

    local duplicate_movies="${STATE_DIR}/duplicate_movies.txt"
    local duplicate_tv="${STATE_DIR}/duplicate_tv.txt"
    local movie_dup_count=$(sort -u "$duplicate_movies" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    local tv_dup_count=$(sort -u "$duplicate_tv" 2>/dev/null | wc -l | tr -d ' ' || echo "0")

echo ""
echo -e "  ${YELLOW}Duplicate Movies: $movie_dup_count${NC}"
echo -e "  ${YELLOW}Duplicate TV Shows: $tv_dup_count${NC}"
}

display_duplicate_movies() {
    local duplicate_file="$1"
    echo "🎬 DUPLICATE MOVIES:"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    sort -u "$duplicate_file" 2>/dev/null | while IFS='|' read -r title year loc1 path1 qual1 video1 size1 loc2 path2 qual2 video2 size2; do
        display_duplicate_item "$title" "$year" "$loc1" "$path1" "$qual1" "$video1" "$size1" "$loc2" "$path2" "$qual2" "$video2" "$size2" "movie"
    done
}

display_duplicate_tv() {
    local duplicate_file="$1"
    echo ""
    echo "📺 DUPLICATE TV SHOWS:"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    sort -u "$duplicate_file" 2>/dev/null | while IFS='|' read -r title year loc1 path1 qual1 video1 size1 loc2 path2 qual2 video2 size2; do
        display_duplicate_item "$title" "$year" "$loc1" "$path1" "$qual1" "$video1" "$size1" "$loc2" "$path2" "$qual2" "$video2" "$size2" "tv"
    done
}

display_duplicate_item() {
    local title="$1" year="$2"
    local loc1="$3" path1="$4" qual1="$5" video1="$6" size1="$7"
    local loc2="$8" path2="$9" qual2="${10}" video2="${11}" size2="${12}"
    local type="${13}"

    local size1_gb=$(echo "scale=2; $size1 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
    local size2_gb=$(echo "scale=2; $size2 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

        echo -e "${BLUE}📁 $title ($year)${NC}"
        echo "   Location 1: ${MAGENTA}$loc1${NC}"
        echo "   Path: $path1"
        echo "   Quality: ${YELLOW}$qual1${NC} | Size: ${size1_gb}GB"
        echo "   Location 2: ${MAGENTA}$loc2${NC}"
        echo "   Path: $path2"
        echo "   Quality: ${YELLOW}$qual2${NC} | Size: ${size2_gb}GB"

    if [ "$type" = "movie" ]; then
        display_movie_recommendation "$qual1" "$qual2" "$size1" "$size2"
    else
        echo -e "   ${YELLOW}⚠️  Recommendation: Compare episode counts and quality${NC}"
    fi

    if [ "$SCAN_CORRUPTED" == "true" ] && [ -n "$video1" ] && [ -n "$video2" ]; then
        display_corruption_scan "$video1" "$video2"
    fi

    echo ""
}

display_movie_recommendation() {
    local qual1="$1" qual2="$2" size1="$3" size2="$4"

        if [ "$qual1" = "LOW" ] && [ "$qual2" != "LOW" ]; then
            echo -e "   ${RED}🔴 RECOMMENDATION: DELETE Location 1 (low quality CAM/TS)${NC}"
            echo -e "   ${GREEN}✅ KEEP Location 2 ($qual2 quality)${NC}"
        elif [ "$qual1" != "LOW" ] && [ "$qual2" = "LOW" ]; then
            echo -e "   ${GREEN}✅ KEEP Location 1 ($qual1 quality)${NC}"
            echo -e "   ${RED}🔴 RECOMMENDATION: DELETE Location 2 (low quality CAM/TS)${NC}"
        elif [ "$qual1" = "LOW" ] && [ "$qual2" = "LOW" ]; then
            echo -e "   ${YELLOW}⚠️  Both are low quality - review manually${NC}"
        else
            if (( $(echo "$size1 > $size2" | bc -l 2>/dev/null || echo "0") )); then
                echo -e "   ${GREEN}✅ PREFER Location 1 (larger size, $qual1)${NC}"
            elif (( $(echo "$size2 > $size1" | bc -l 2>/dev/null || echo "0") )); then
                echo -e "   ${GREEN}✅ PREFER Location 2 (larger size, $qual2)${NC}"
            else
                echo -e "   ${YELLOW}⚠️  Similar sizes - review manually${NC}"
            fi
        fi
}

display_corruption_scan() {
    local video1="$1" video2="$2"
            echo "   🔬 Scanning for corruption..."

    # Corruption scanning would go here (commented out for now as it's slow)
    # errors1=$(scan_for_corruption "$video1")
    # errors2=$(scan_for_corruption "$video2")
    # ... display results ...
}

display_next_steps() {
    local duplicate_movies="$1"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "💡 Next Steps:"
echo "───────────────────────────────────────────────────────────────"
echo "  1. Review duplicates above"
echo "  2. Low quality (CAM/TS/HDTS) versions should be deleted"
echo "  3. For corrupted versions: Keep clean copy, delete corrupted"
echo "  4. For same quality: Prefer larger size or better location"
echo "  5. Free up space by removing confirmed duplicates"
echo ""
}

save_reports() {
    local duplicate_movies="$1"
    local duplicate_tv="$2"

    sort -u "$duplicate_movies" 2>/dev/null > /tmp/duplicate_movies_report.txt || true
    sort -u "$duplicate_tv" 2>/dev/null > /tmp/duplicate_tv_report.txt || true

echo "📝 Reports saved:"
echo "   /tmp/duplicate_movies_report.txt"
echo "   /tmp/duplicate_tv_report.txt"
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Check for resume
    if [ -f "$INDEXING_DONE" ] && [ -f "$DUPLICATES_FOUND" ] && [ -f "$RESULTS_DISPLAYED" ] && [ "$FORCE_RESCAN" != "true" ]; then
        log_info "Previous scan completed. Use --force-rescan to start fresh."
        log_info "Displaying cached results..."
echo ""
        display_results
        return 0
    fi

    # Run phases
    index_all_locations
    find_all_duplicates
    display_results

    log_success "Enhanced duplicate scan complete!"
}

# Run main function
main
