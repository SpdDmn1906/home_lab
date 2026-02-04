#!/bin/bash
#
# Quarantine Tracked Duplicates (Resumable with Parallel Processing)
# Moves duplicate files that are tracked in Radarr/Sonarr to quarantine
# Only moves files that are confirmed to be tracked for safety
# Supports resuming from interruptions and parallel processing
#

set -e

# Configuration
QUARANTINE_BASE="/data/media/.quarantine"
QUARANTINE_MOVIES="${QUARANTINE_BASE}/Movies"
QUARANTINE_TV="${QUARANTINE_BASE}/TV Shows"
QUARANTINE_LOG="${QUARANTINE_BASE}/quarantine.log"
RECOMMENDATIONS_FILE="/tmp/duplicate_starr_tracking_recommendations.txt"
STATE_DIR="/tmp/quarantine_state"
PROCESSED_FILE="${STATE_DIR}/processed.txt"
QUEUE_FILE="${STATE_DIR}/queue.txt"
MAX_PARALLEL=4  # Number of parallel operations

# API endpoints
RADARR_ENDPOINT="http://localhost:7878/api/v3"
SONARR_ENDPOINT="http://localhost:8989/api/v3"

# Get API keys
RADARR_KEY=$(docker exec radarr cat /config/config.xml 2>/dev/null | grep -oP '<ApiKey>\K[^<]+' || echo "")
SONARR_KEY=$(docker exec sonarr cat /config/config.xml 2>/dev/null | grep -oP '<ApiKey>\K[^<]+' || echo "")

if [ -z "$RADARR_KEY" ] || [ -z "$SONARR_KEY" ]; then
    echo "❌ Could not extract Radarr/Sonarr API keys"
    exit 1
fi

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$QUARANTINE_LOG"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$QUARANTINE_LOG"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$QUARANTINE_LOG"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$QUARANTINE_LOG"
}

# Normalize path for comparison
normalize_path_for_match() {
    local path="$1"
    echo "$path" | sed 's|/home/youruser/synology/Media|/data/media|g' | sed 's|/$||'
}

# Extract title and year from path
extract_title_year_from_path() {
    local path="$1"
    local basename=$(basename "$path" | sed 's|/$||')
    if echo "$basename" | grep -qE '\([0-9]{4}\)'; then
        echo "$basename" | sed -E 's/^(.+)\s+\(([0-9]{4})\).*/\1|\2/'
    else
        echo "$basename|"
    fi
}

# ============================================================================
# TRACKING VERIFICATION
# ============================================================================

# Fetch tracked movies from Radarr
fetch_tracked_movies() {
    local tracked_file="/tmp/radarr_tracked_movies_quarantine.txt"
    : > "$tracked_file"

    curl -s -H "X-Api-Key: $RADARR_KEY" "${RADARR_ENDPOINT}/movie" 2>/dev/null | \
        python3 -c "
import sys, json, re
try:
    movies = json.load(sys.stdin)
    for m in movies:
        path = m.get('path', '')
        title = m.get('title', '')
        year = m.get('year', 0)
        monitored = m.get('monitored', False)
        has_file = m.get('hasFile', False)
        if path:
            norm_path = path.replace('/home/youruser/synology/Media', '/data/media').rstrip('/')
            search_title = re.sub(r'[^a-z0-9]', '', title.lower()) if title else ''
            print(f\"{norm_path}|{path}|{title}|{year}|{monitored}|{has_file}|{search_title}\")
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    pass
" >> "$tracked_file" 2>/dev/null

    echo "$tracked_file"
}

# Fetch tracked TV shows from Sonarr
fetch_tracked_series() {
    local tracked_file="/tmp/sonarr_tracked_series_quarantine.txt"
    : > "$tracked_file"

    curl -s -H "X-Api-Key: $SONARR_KEY" "${SONARR_ENDPOINT}/series" 2>/dev/null | \
        python3 -c "
import sys, json, re
try:
    series = json.load(sys.stdin)
    for s in series:
        path = s.get('path', '')
        title = s.get('title', '')
        year = s.get('year', 0)
        monitored = s.get('monitored', False)
        if path:
            norm_path = path.replace('/home/youruser/synology/Media', '/data/media').rstrip('/')
            search_title = re.sub(r'[^a-z0-9]', '', title.lower()) if title else ''
            print(f\"{norm_path}|{path}|{title}|{year}|{monitored}|{search_title}\")
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    pass
" >> "$tracked_file" 2>/dev/null

    echo "$tracked_file"
}

# Check if a movie path is tracked in Radarr
is_tracked_movie() {
    local path="$1"
    local tracked_file="$2"
    local dup_title="${3:-}"
    local dup_year="${4:-}"

    local normalized_path=$(normalize_path_for_match "$path")
    local match=""

    # Try exact path match
    match=$(grep "^${normalized_path}|" "$tracked_file" 2>/dev/null | head -1)

    # If no exact match and we have title/year, try that
    if [ -z "$match" ] && [ -n "$dup_title" ] && [ -n "$dup_year" ]; then
        local search_title=$(echo "$dup_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
        match=$(grep "|${dup_year}|.*|${search_title}$" "$tracked_file" 2>/dev/null | head -1)
    fi

    # If still no match, try extracting from path
    if [ -z "$match" ]; then
        local title_year=$(extract_title_year_from_path "$path")
        if [ -n "$title_year" ] && [ "$title_year" != "|" ]; then
            IFS='|' read -r title year <<< "$title_year"
            if [ -n "$title" ] && [ -n "$year" ]; then
                local search_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
                match=$(grep "|${year}|.*|${search_title}$" "$tracked_file" 2>/dev/null | head -1)
            fi
        fi
    fi

    if [ -n "$match" ]; then
        IFS='|' read -r norm_path orig_path title year monitored has_file search_title <<< "$match"
        local hf_lower=$(echo "$has_file" | tr '[:upper:]' '[:lower:]')
        local m_lower=$(echo "$monitored" | tr '[:upper:]' '[:lower:]')
        if [ "$hf_lower" = "true" ] || [ "$m_lower" = "true" ]; then
            return 0
        fi
    fi

    return 1
}

# Check if a TV show path is tracked in Sonarr
is_tracked_series() {
    local path="$1"
    local tracked_file="$2"
    local dup_title="${3:-}"

    local normalized_path=$(normalize_path_for_match "$path")
    local match=""

    # Try exact path match
    match=$(grep "^${normalized_path}|" "$tracked_file" 2>/dev/null | head -1)

    # If no exact match, try parent directories
    if [ -z "$match" ]; then
        local dir_path="$normalized_path"
        while [ "$dir_path" != "/" ] && [ "$dir_path" != "." ] && [ "$dir_path" != "/data" ] && [ "$dir_path" != "/data/media" ]; do
            match=$(grep "^${dir_path}|" "$tracked_file" 2>/dev/null | head -1)
            if [ -n "$match" ]; then
                break
            fi
            dir_path=$(dirname "$dir_path")
        done
    fi

    # If still no match and we have title, try title matching
    if [ -z "$match" ] && [ -n "$dup_title" ]; then
        local search_title=$(echo "$dup_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
        # Match by search_title (last field)
        match=$(grep "|.*|${search_title}$" "$tracked_file" 2>/dev/null | head -1)
    fi

    # If still no match, try extracting series name from path
    if [ -z "$match" ]; then
        # Extract series name from path (e.g., "Archer (2009)" from "/external/media/TV/Archer (2009)")
        local series_name=$(basename "$path" | sed 's|/$||' | sed -E 's/^([A-Za-z].*)\s+\([0-9]{4}\).*/\1/' | head -1)
        if [ -n "$series_name" ] && [ "$series_name" != "$(basename "$path")" ]; then
            local search_title=$(echo "$series_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
            match=$(grep "|.*|${search_title}$" "$tracked_file" 2>/dev/null | head -1)
        fi
    fi

    if [ -n "$match" ]; then
        IFS='|' read -r norm_path orig_path title year monitored search_title <<< "$match"
        local m_lower=$(echo "$monitored" | tr '[:upper:]' '[:lower:]')
        if [ "$m_lower" = "true" ]; then
            return 0
        fi
    fi

    return 1
}

# ============================================================================
# QUARANTINE OPERATIONS
# ============================================================================

# Determine if path is a movie or TV show
get_media_type() {
    local path="$1"
    if echo "$path" | grep -qiE "(movies|movie)"; then
        echo "movie"
    elif echo "$path" | grep -qiE "(tv|tv shows|series)"; then
        echo "tv"
    else
        # Try to infer from path structure
        if echo "$path" | grep -qE "/Movies"; then
            echo "movie"
        elif echo "$path" | grep -qE "/TV Shows|/TV/"; then
            echo "tv"
        else
            echo "unknown"
        fi
    fi
}

# Move file/directory to quarantine
quarantine_item() {
    local source_path="$1"
    local media_type="$2"
    local reason="$3"

    if [ ! -e "$source_path" ]; then
        log_warning "Path does not exist: $source_path"
        return 1
    fi

    # Determine quarantine destination
    local quarantine_dir
    if [ "$media_type" = "movie" ]; then
        quarantine_dir="$QUARANTINE_MOVIES"
    elif [ "$media_type" = "tv" ]; then
        quarantine_dir="$QUARANTINE_TV"
    else
        quarantine_dir="$QUARANTINE_BASE/Unknown"
    fi

    # Create quarantine directory structure
    mkdir -p "$quarantine_dir"

    # Get item name and create destination
    local item_name=$(basename "$source_path")
    local dest_path="${quarantine_dir}/${item_name}"

    # Handle name conflicts
    local counter=1
    while [ -e "$dest_path" ]; do
        dest_path="${quarantine_dir}/${item_name}.${counter}"
        counter=$((counter + 1))
    done

    # Move the item
    if mv "$source_path" "$dest_path" 2>/dev/null; then
        log_success "Quarantined: $source_path -> $dest_path (Reason: $reason)"
        echo "  Source: $source_path" >> "$QUARANTINE_LOG"
        echo "  Destination: $dest_path" >> "$QUARANTINE_LOG"
        echo "  Reason: $reason" >> "$QUARANTINE_LOG"
        return 0
    else
        log_error "Failed to quarantine: $source_path"
        return 1
    fi
}

# ============================================================================
# RESUME SUPPORT
# ============================================================================

# Initialize state directory
init_state() {
    mkdir -p "$STATE_DIR"
    touch "$PROCESSED_FILE" "$QUEUE_FILE"
}

# Check if item was already processed
is_processed() {
    local path="$1"
    grep -Fxq "$path" "$PROCESSED_FILE" 2>/dev/null
}

# Mark item as processed
mark_processed() {
    local path="$1"
    echo "$path" >> "$PROCESSED_FILE"
}

# Build queue from recommendations
build_queue() {
    log_info "Building processing queue..."
    : > "$QUEUE_FILE"

    local current_title=""
    local current_year=""

    while IFS= read -r line; do
        [ -z "$line" ] && continue

        if echo "$line" | grep -q "^❌ DELETE:"; then
            local delete_path=$(echo "$line" | sed 's/^❌ DELETE: //')
            # Only add if not already processed
            if ! is_processed "$delete_path"; then
                echo "${delete_path}|${current_title}|${current_year}" >> "$QUEUE_FILE"
            fi
        elif echo "$line" | grep -q "^⚠️  REVIEW:"; then
            current_title=$(echo "$line" | sed 's/^⚠️  REVIEW: //' | sed 's/ ([0-9]*)$//' | tr '[:upper:]' '[:lower:]')
            current_year=$(echo "$line" | grep -oE '\([0-9]{4}\)' | tr -d '()' || echo "")
        fi
    done < "$RECOMMENDATIONS_FILE"

    local queue_count=$(wc -l < "$QUEUE_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    log_success "Queue built: $queue_count items to process"
}

# Process a single item (worker function)
process_item() {
    local item_info="$1"
    local movies_tracked="$2"
    local series_tracked="$3"

    IFS='|' read -r delete_path current_title current_year <<< "$item_info"

    # Skip if already processed (race condition check)
    if is_processed "$delete_path"; then
        return 0
    fi

    # Determine media type
    local media_type=$(get_media_type "$delete_path")

    # Check if tracked
    local is_tracked=false
    if [ "$media_type" = "movie" ]; then
        if is_tracked_movie "$delete_path" "$movies_tracked" "$current_title" "$current_year"; then
            is_tracked=true
        fi
    elif [ "$media_type" = "tv" ]; then
        if is_tracked_series "$delete_path" "$series_tracked" "$current_title"; then
            is_tracked=true
        fi
    fi

    # Since goal is to have everything tracked, quarantine ALL duplicates
    # but mark untracked ones for later addition to Radarr/Sonarr
    if [ "$is_tracked" = "true" ]; then
        if quarantine_item "$delete_path" "$media_type" "Tracked duplicate"; then
            mark_processed "$delete_path"
            echo "SUCCESS|$delete_path"
            return 0
        else
            echo "ERROR|$delete_path"
            return 1
        fi
    else
        # Quarantine untracked items too (they should be tracked)
        if quarantine_item "$delete_path" "$media_type" "Untracked duplicate (needs Radarr/Sonarr addition)"; then
            mark_processed "$delete_path"
            echo "SUCCESS_UNTRACKED|$delete_path"
            return 0
        else
            echo "ERROR|$delete_path"
            return 1
        fi
    fi
}

# Process queue with parallel workers
process_queue() {
    local movies_tracked="$1"
    local series_tracked="$2"

    log_info "Processing queue with $MAX_PARALLEL parallel workers..."

    # Filter out already processed items from queue
    local filtered_queue="${STATE_DIR}/queue_filtered_$$.txt"
    : > "$filtered_queue"
    while IFS= read -r item_info; do
        IFS='|' read -r delete_path current_title current_year <<< "$item_info"
        if ! is_processed "$delete_path"; then
            echo "$item_info" >> "$filtered_queue"
        fi
    done < "$QUEUE_FILE"

    # Replace queue with filtered version
    mv "$filtered_queue" "$QUEUE_FILE"

    local total=$(wc -l < "$QUEUE_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    if [ "$total" -eq 0 ]; then
        log_info "All items already processed. Nothing to do."
        return 0
    fi

    local processed=0
    local quarantined=0
    local skipped_not_tracked=0
    local errors=0

    # Create temporary files for results
    local results_file="${STATE_DIR}/results_$$.txt"
    : > "$results_file"

    # Export tracked files paths and functions for parallel workers
    export movies_tracked series_tracked
    export -f process_item quarantine_item get_media_type is_tracked_movie is_tracked_series normalize_path_for_match
    export -f normalize_path_for_match extract_title_year_from_path is_processed mark_processed
    export QUARANTINE_BASE QUARANTINE_MOVIES QUARANTINE_TV QUARANTINE_LOG PROCESSED_FILE

    # Process queue in parallel batches
    while IFS= read -r item_info; do
        # Wait if we have too many parallel jobs
        while [ $(jobs -r | wc -l) -ge $MAX_PARALLEL ]; do
            sleep 0.5
        done

        # Process item in background
        (
            process_item "$item_info" "$movies_tracked" "$series_tracked" >> "$results_file" 2>&1
        ) &

        processed=$((processed + 1))
        if [ $((processed % 10)) -eq 0 ]; then
            log_info "Progress: $processed/$total items processed ($(jobs -r | wc -l) active workers)"
        fi
    done < "$QUEUE_FILE"

    # Wait for all background jobs to complete
    wait

    # Count results
    while IFS='|' read -r status path; do
        case "$status" in
            SUCCESS) quarantined=$((quarantined + 1)) ;;
            SUCCESS_UNTRACKED) quarantined=$((quarantined + 1)); skipped_not_tracked=$((skipped_not_tracked + 1)) ;;
            SKIPPED) skipped_not_tracked=$((skipped_not_tracked + 1)) ;;
            ERROR) errors=$((errors + 1)) ;;
        esac
    done < "$results_file"

    rm -f "$results_file"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Quarantine Summary:"
    echo "  ✅ Quarantined: $quarantined"
    if [ "$skipped_not_tracked" -gt 0 ]; then
        echo "  ⚠️  Untracked items quarantined (need Radarr/Sonarr addition): $skipped_not_tracked"
    fi
    echo "  ❌ Errors: $errors"
    echo "  📊 Total processed: $processed"
    echo ""
    echo "📝 Log: $QUARANTINE_LOG"
    echo "📁 Quarantine location: $QUARANTINE_BASE"
    if [ "$skipped_not_tracked" -gt 0 ]; then
        echo ""
        echo "⚠️  NOTE: $skipped_not_tracked untracked items were quarantined."
        echo "   These should be added to Radarr/Sonarr before final deletion."
    fi
    echo ""
}

# Main processing function
process_recommendations() {
    if [ ! -f "$RECOMMENDATIONS_FILE" ]; then
        log_error "Recommendations file not found: $RECOMMENDATIONS_FILE"
        log_info "Run analyze_duplicates_with_starr_tracking.sh first"
        return 1
    fi

    # Initialize state
    init_state

    # Check if we should resume or start fresh
    local resume=false
    if [ -f "$QUEUE_FILE" ] && [ -s "$QUEUE_FILE" ]; then
        local remaining=$(wc -l < "$QUEUE_FILE" 2>/dev/null | tr -d ' ' || echo "0")
        if [ "$remaining" -gt 0 ]; then
            log_info "Resuming from previous session ($remaining items remaining)"
            resume=true
        fi
    fi

    if [ "$resume" = "false" ]; then
        log_info "Fetching tracked movies from Radarr..."
        local movies_tracked=$(fetch_tracked_movies)
        local movies_count=$(wc -l < "$movies_tracked" 2>/dev/null | tr -d ' ' || echo "0")
        log_success "Found $movies_count tracked movies"

        log_info "Fetching tracked TV shows from Sonarr..."
        local series_tracked=$(fetch_tracked_series)
        local series_count=$(wc -l < "$series_tracked" 2>/dev/null | tr -d ' ' || echo "0")
        log_success "Found $series_count tracked TV shows"

        echo ""
        log_info "Building processing queue..."
        build_queue

        # Save tracked files path for resume
        echo "$movies_tracked" > "${STATE_DIR}/movies_tracked.txt"
        echo "$series_tracked" > "${STATE_DIR}/series_tracked.txt"
    else
        log_info "Loading tracked data from previous session..."
        local movies_tracked=$(cat "${STATE_DIR}/movies_tracked.txt" 2>/dev/null || fetch_tracked_movies)
        local series_tracked=$(cat "${STATE_DIR}/series_tracked.txt" 2>/dev/null || fetch_tracked_series)
    fi

    # Create quarantine directories
    mkdir -p "$QUARANTINE_MOVIES" "$QUARANTINE_TV"

    # Process queue
    process_queue "$movies_tracked" "$series_tracked"

    # Clean up queue if complete
    local remaining=$(wc -l < "$QUEUE_FILE" 2>/dev/null | tr -d ' ' || echo "0")
    if [ "$remaining" -eq 0 ]; then
        log_success "All items processed. Cleaning up state..."
        rm -f "${STATE_DIR}/movies_tracked.txt" "${STATE_DIR}/series_tracked.txt"
    fi
}

# Main
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  🗂️  QUARANTINE TRACKED DUPLICATES                           ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Initialize log
    mkdir -p "$QUARANTINE_BASE"
    echo "=== Quarantine Session Started ===" >> "$QUARANTINE_LOG"
    echo "Date: $(date)" >> "$QUARANTINE_LOG"
    echo "" >> "$QUARANTINE_LOG"

    process_recommendations

    echo "=== Quarantine Session Ended ===" >> "$QUARANTINE_LOG"
    echo "" >> "$QUARANTINE_LOG"
}

main

