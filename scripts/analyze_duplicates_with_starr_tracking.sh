#!/bin/bash
#
# Analyze Duplicates with STARR Tracking Cross-Reference
# Provides recommendations based on:
# - What Radarr/Sonarr are actually tracking
# - STARR-managed locations
# - File organization and quality
#

set -e

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

# Reports
MOVIES_REPORT="/tmp/duplicate_movies_report.txt"
TV_REPORT="/tmp/duplicate_tv_report.txt"
STARR_RECOMMENDATIONS="/tmp/duplicate_starr_tracking_recommendations.txt"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  📊 DUPLICATE ANALYSIS WITH STARR TRACKING CROSS-REFERENCE    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# STARR TRACKING DATA
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

# Normalize path for comparison (handle bind mounts)
normalize_path_for_match() {
    local path="$1"
    # Convert /home/youruser/synology/Media to /data/media
    echo "$path" | sed 's|/home/youruser/synology/Media|/data/media|g' | sed 's|/$||'
}

# Extract title and year from path
extract_title_year_from_path() {
    local path="$1"
    local basename=$(basename "$path" | sed 's|/$||')
    # Try to extract "Title (Year)" pattern
    if echo "$basename" | grep -qE '\([0-9]{4}\)'; then
        echo "$basename" | sed -E 's/^(.+)\s+\(([0-9]{4})\).*/\1|\2/'
    else
        echo "$basename|"
    fi
}

# Fetch tracked movies from Radarr
fetch_tracked_movies() {
    log_info "Fetching tracked movies from Radarr..."

    local tracked_file="/tmp/radarr_tracked_movies.txt"
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
            # Normalize path
            norm_path = path.replace('/home/youruser/synology/Media', '/data/media').rstrip('/')
            # Create searchable title (lowercase, no special chars)
            search_title = re.sub(r'[^a-z0-9]', '', title.lower()) if title else ''
            print(f\"{norm_path}|{path}|{title}|{year}|{monitored}|{has_file}|{search_title}\")
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    pass
" >> "$tracked_file" 2>/dev/null

    local count=$(wc -l < "$tracked_file" 2>/dev/null | tr -d ' ' || echo "0")
    log_success "Found $count tracked movies"
    echo "$tracked_file"
}

# Fetch tracked TV shows from Sonarr
fetch_tracked_series() {
    log_info "Fetching tracked TV shows from Sonarr..."

    local tracked_file="/tmp/sonarr_tracked_series.txt"
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
            # Normalize path
            norm_path = path.replace('/home/youruser/synology/Media', '/data/media').rstrip('/')
            # Create searchable title
            search_title = re.sub(r'[^a-z0-9]', '', title.lower()) if title else ''
            print(f\"{norm_path}|{path}|{title}|{year}|{monitored}|{search_title}\")
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    pass
" >> "$tracked_file" 2>/dev/null

    local count=$(wc -l < "$tracked_file" 2>/dev/null | tr -d ' ' || echo "0")
    log_success "Found $count tracked TV shows"
    echo "$tracked_file"
}

# Check if path is tracked in Radarr
is_tracked_movie() {
    local path="$1"
    local tracked_file="$2"

    # Normalize path
    local normalized_path=$(normalize_path_for_match "$path")

    # Check exact match on normalized path (first field)
    if grep -q "^${normalized_path}|" "$tracked_file" 2>/dev/null; then
        return 0
    fi

    # Check if any parent directory is tracked
    local dir_path="$normalized_path"
    while [ "$dir_path" != "/" ] && [ "$dir_path" != "." ] && [ "$dir_path" != "/data" ] && [ "$dir_path" != "/data/media" ]; do
        if grep -q "^${dir_path}|" "$tracked_file" 2>/dev/null; then
            return 0
        fi
        dir_path=$(dirname "$dir_path")
    done

    # Try matching by title/year from path
    local title_year=$(extract_title_year_from_path "$path")
    if [ -n "$title_year" ] && [ "$title_year" != "|" ]; then
        IFS='|' read -r title year <<< "$title_year"
        if [ -n "$title" ] && [ -n "$year" ]; then
            # Search for matching title/year in tracked file
            local search_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
            if grep -q "|${year}|.*|${search_title}" "$tracked_file" 2>/dev/null; then
                return 0
            fi
        fi
    fi

    return 1
}

# Check if path is tracked in Sonarr
is_tracked_series() {
    local path="$1"
    local tracked_file="$2"

    local normalized_path=$(normalize_path_for_match "$path")

    if grep -q "^${normalized_path}|" "$tracked_file" 2>/dev/null; then
        return 0
    fi

    # Check parent directories
    local dir_path="$normalized_path"
    while [ "$dir_path" != "/" ] && [ "$dir_path" != "." ] && [ "$dir_path" != "/data" ] && [ "$dir_path" != "/data/media" ]; do
        if grep -q "^${dir_path}|" "$tracked_file" 2>/dev/null; then
            return 0
        fi
        dir_path=$(dirname "$dir_path")
    done

    return 1
}

# Get tracking info for a movie path (with optional title/year for better matching)
get_movie_tracking_info() {
    local path="$1"
    local tracked_file="$2"
    local dup_title="${3:-}"  # Optional: title from duplicate report
    local dup_year="${4:-}"   # Optional: year from duplicate report

    local normalized_path=$(normalize_path_for_match "$path")
    local match=""

    # Try exact path match first
    match=$(grep "^${normalized_path}|" "$tracked_file" 2>/dev/null | head -1)

    # If no exact match and we have title/year from duplicate report, try that FIRST (more accurate)
    if [ -z "$match" ] && [ -n "$dup_title" ] && [ -n "$dup_year" ]; then
        local search_title=$(echo "$dup_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
        # Match by year and search_title (last field)
        match=$(grep "|${dup_year}|.*|${search_title}$" "$tracked_file" 2>/dev/null | head -1)
    fi

    # If still no match, try parent directories (less accurate, but might work)
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

    # If still no match, try extracting title/year from path
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
        # Format: norm_path|orig_path|title|year|monitored|has_file|search_title
        IFS='|' read -r norm_path orig_path title year monitored has_file search_title <<< "$match"
        echo "${monitored}|${has_file}|${title}|${year}"
    else
        echo "false|false||0"
    fi
}

# Get tracking info for a TV show path
get_series_tracking_info() {
    local path="$1"
    local tracked_file="$2"

    local normalized_path=$(normalize_path_for_match "$path")

    # Try exact path match first
    local match=$(grep "^${normalized_path}|" "$tracked_file" 2>/dev/null | head -1)

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

    if [ -n "$match" ]; then
        # Format: norm_path|orig_path|title|year|monitored|search_title
        IFS='|' read -r norm_path orig_path title year monitored search_title <<< "$match"
        echo "${monitored}|${title}|${year}"
    else
        echo "false||0"
    fi
}

# ============================================================================
# PATH UTILITIES
# ============================================================================

is_starr_managed() {
    local path="$1"
    if [[ "$path" == /data/media/* ]] || [[ "$path" == /home/youruser/synology/Media/* ]]; then
        return 0
    else
        return 1
    fi
}

is_external_path() {
    local path="$1"
    if [[ "$path" == /external/media/* ]]; then
        return 0
    else
        return 1
    fi
}

get_organization_score() {
    local path="$1"
    local basename=$(basename "$path")

    if echo "$path" | grep -qE "/[^/]+ \([0-9]{4}\)"; then
        echo "10"
    elif echo "$basename" | grep -qE "^[A-Za-z].*\([0-9]{4}\)"; then
        echo "8"
    elif echo "$basename" | grep -qE "[0-9]{4}"; then
        echo "6"
    else
        echo "4"
    fi
}

get_quality_score() {
    local quality="$1"
    case "$quality" in
        BLURAY) echo "10" ;;
        WEB) echo "8" ;;
        DVD) echo "6" ;;
        LOW) echo "2" ;;
        UNKNOWN) echo "5" ;;
        *) echo "5" ;;
    esac
}

# ============================================================================
# RECOMMENDATION ENGINE
# ============================================================================

recommend_movie_keep() {
    local loc1="$1" path1="$2" qual1="$3" size1="$4"
    local loc2="$5" path2="$6" qual2="$7" size2="$8"
    local tracked_file="$9"
    local dup_title="${10:-}"  # Optional: title from duplicate report
    local dup_year="${11:-}"   # Optional: year from duplicate report

    local score1=0 score2=0

    # Priority 1: TRACKED in Radarr (highest priority - 100 points)
    local track1_info=$(get_movie_tracking_info "$path1" "$tracked_file" "$dup_title" "$dup_year")
    local track2_info=$(get_movie_tracking_info "$path2" "$tracked_file" "$dup_title" "$dup_year")
    IFS='|' read -r monitored1 has_file1 title1 year1 <<< "$track1_info"
    IFS='|' read -r monitored2 has_file2 title2 year2 <<< "$track2_info"

    local tracked1=false tracked2=false
    # Python outputs "True"/"False", bash needs lowercase comparison
    local hf1_lower=$(echo "$has_file1" | tr '[:upper:]' '[:lower:]')
    local m1_lower=$(echo "$monitored1" | tr '[:upper:]' '[:lower:]')
    local hf2_lower=$(echo "$has_file2" | tr '[:upper:]' '[:lower:]')
    local m2_lower=$(echo "$monitored2" | tr '[:upper:]' '[:lower:]')

    if [ "$hf1_lower" = "true" ] || [ "$m1_lower" = "true" ]; then
        score1=$((score1 + 100))  # Tracked = keep
        tracked1=true
    fi
    if [ "$hf2_lower" = "true" ] || [ "$m2_lower" = "true" ]; then
        score2=$((score2 + 100))  # Tracked = keep
        tracked2=true
    fi

    # If one is tracked and other isn't, decision is clear
    if [ "$tracked1" = "true" ] && [ "$tracked2" = "false" ]; then
        echo "KEEP1|TRACKED"
        return 0
    fi
    if [ "$tracked2" = "true" ] && [ "$tracked1" = "false" ]; then
        echo "KEEP2|TRACKED"
        return 0
    fi

    # If both are tracked (same movie), check which path matches Radarr's path exactly
    if [ "$tracked1" = "true" ] && [ "$tracked2" = "true" ]; then
        local norm_path1=$(normalize_path_for_match "$path1")
        local norm_path2=$(normalize_path_for_match "$path2")
        # Check which path exactly matches a tracked path
        local exact_match1=$(grep "^${norm_path1}|" "$tracked_file" 2>/dev/null | head -1)
        local exact_match2=$(grep "^${norm_path2}|" "$tracked_file" 2>/dev/null | head -1)

        if [ -n "$exact_match1" ] && [ -z "$exact_match2" ]; then
            echo "KEEP1|TRACKED_EXACT"
            return 0
        fi
        if [ -n "$exact_match2" ] && [ -z "$exact_match1" ]; then
            echo "KEEP2|TRACKED_EXACT"
            return 0
        fi
        # If both match exactly or neither matches exactly, continue to other criteria
    fi

    # Priority 2: STARR-managed location (10 points)
    if is_starr_managed "$path1"; then score1=$((score1 + 10)); fi
    if is_starr_managed "$path2"; then score2=$((score2 + 10)); fi

    # Priority 3: Organization (up to 10 points)
    local org1=$(get_organization_score "$path1")
    local org2=$(get_organization_score "$path2")
    score1=$((score1 + org1))
    score2=$((score2 + org2))

    # Priority 4: Quality (up to 10 points)
    local qual_score1=$(get_quality_score "$qual1")
    local qual_score2=$(get_quality_score "$qual2")
    score1=$((score1 + qual_score1))
    score2=$((score2 + qual_score2))

    # Priority 5: Size (if quality is same, prefer larger)
    if [ "$qual1" = "$qual2" ] && [ "$qual1" != "LOW" ]; then
        if (( $(echo "$size1 > $size2" | bc -l 2>/dev/null || echo "0") )); then
            score1=$((score1 + 3))
        elif (( $(echo "$size2 > $size1" | bc -l 2>/dev/null || echo "0") )); then
            score2=$((score2 + 3))
        fi
    fi

    # Priority 6: External paths deprioritized (-5 points)
    if is_external_path "$path1"; then score1=$((score1 - 5)); fi
    if is_external_path "$path2"; then score2=$((score2 - 5)); fi

    # Decision
    if [ "$score1" -gt "$score2" ]; then
        echo "KEEP1|SCORE"
    elif [ "$score2" -gt "$score1" ]; then
        echo "KEEP2|SCORE"
    else
        echo "REVIEW|TIE"
    fi
}

recommend_series_keep() {
    local loc1="$1" path1="$2" qual1="$3" size1="$4"
    local loc2="$5" path2="$6" qual2="$7" size2="$8"
    local tracked_file="$9"

    local score1=0 score2=0

    # Priority 1: TRACKED in Sonarr (highest priority - 100 points)
    local track1_info=$(get_series_tracking_info "$path1" "$tracked_file")
    local track2_info=$(get_series_tracking_info "$path2" "$tracked_file")
    IFS='|' read -r monitored1 title1 year1 <<< "$track1_info"
    IFS='|' read -r monitored2 title2 year2 <<< "$track2_info"

    local m1_lower=$(echo "$monitored1" | tr '[:upper:]' '[:lower:]')
    local m2_lower=$(echo "$monitored2" | tr '[:upper:]' '[:lower:]')
    if [ "$m1_lower" = "true" ]; then
        score1=$((score1 + 100))
    fi
    if [ "$m2_lower" = "true" ]; then
        score2=$((score2 + 100))
    fi

    # If one is tracked and other isn't, decision is clear
    if [ "$score1" -gt 50 ] && [ "$score2" -lt 50 ]; then
        echo "KEEP1|TRACKED"
        return 0
    fi
    if [ "$score2" -gt 50 ] && [ "$score1" -lt 50 ]; then
        echo "KEEP2|TRACKED"
        return 0
    fi

    # Priority 2: STARR-managed location
    if is_starr_managed "$path1"; then score1=$((score1 + 10)); fi
    if is_starr_managed "$path2"; then score2=$((score2 + 10)); fi

    # Priority 3: Organization
    local org1=$(get_organization_score "$path1")
    local org2=$(get_organization_score "$path2")
    score1=$((score1 + org1))
    score2=$((score2 + org2))

    # Priority 4: Quality
    local qual_score1=$(get_quality_score "$qual1")
    local qual_score2=$(get_quality_score "$qual2")
    score1=$((score1 + qual_score1))
    score2=$((score2 + qual_score2))

    # Priority 5: Size
    if [ "$qual1" = "$qual2" ] && [ "$qual1" != "LOW" ]; then
        if (( $(echo "$size1 > $size2" | bc -l 2>/dev/null || echo "0") )); then
            score1=$((score1 + 3))
        elif (( $(echo "$size2 > $size1" | bc -l 2>/dev/null || echo "0") )); then
            score2=$((score2 + 3))
        fi
    fi

    # External deprioritized
    if is_external_path "$path1"; then score1=$((score1 - 5)); fi
    if is_external_path "$path2"; then score2=$((score2 - 5)); fi

    if [ "$score1" -gt "$score2" ]; then
        echo "KEEP1|SCORE"
    elif [ "$score2" -gt "$score1" ]; then
        echo "KEEP2|SCORE"
    else
        echo "REVIEW|TIE"
    fi
}

# ============================================================================
# ANALYSIS
# ============================================================================

analyze_movies() {
    echo "🎬 Analyzing Movie Duplicates with Radarr Tracking..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ ! -f "$MOVIES_REPORT" ] || [ ! -s "$MOVIES_REPORT" ]; then
        log_warning "No movie duplicates report found"
        return 1
    fi

    local tracked_file=$(fetch_tracked_movies)
    echo ""

    : > "$STARR_RECOMMENDATIONS"

    local keep_tracked=0 keep_starr=0 keep_external=0 review=0
    local delete_tracked=0 delete_untracked=0
    local total_size_savings=0

    while IFS='|' read -r title year loc1 path1 qual1 video1 size1 loc2 path2 qual2 video2 size2; do
        local recommendation=$(recommend_movie_keep "$loc1" "$path1" "$qual1" "$size1" "$loc2" "$path2" "$qual2" "$size2" "$tracked_file" "$title" "$year")
        IFS='|' read -r decision reason <<< "$recommendation"

        local size1_gb=$(echo "scale=2; $size1 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
        local size2_gb=$(echo "scale=2; $size2 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

        # Get tracking info (with title/year for better matching)
        local track1_info=$(get_movie_tracking_info "$path1" "$tracked_file" "$title" "$year")
        local track2_info=$(get_movie_tracking_info "$path2" "$tracked_file" "$title" "$year")
        IFS='|' read -r monitored1 has_file1 title1 year1 <<< "$track1_info"
        IFS='|' read -r monitored2 has_file2 title2 year2 <<< "$track2_info"

        case "$decision" in
            KEEP1)
                if [ "$reason" = "TRACKED" ] || [ "$reason" = "TRACKED_EXACT" ]; then
                    keep_tracked=$((keep_tracked + 1))
                    delete_untracked=$((delete_untracked + 1))
                elif is_starr_managed "$path1"; then
                    keep_starr=$((keep_starr + 1))
                elif is_external_path "$path1"; then
                    keep_external=$((keep_external + 1))
                fi
                total_size_savings=$((total_size_savings + size2))

                echo "✅ KEEP: $path1" >> "$STARR_RECOMMENDATIONS"
                local hf1_lower=$(echo "$has_file1" | tr '[:upper:]' '[:lower:]')
                local m1_lower=$(echo "$monitored1" | tr '[:upper:]' '[:lower:]')
                if [ "$hf1_lower" = "true" ] || [ "$m1_lower" = "true" ]; then
                    echo "   📌 TRACKED in Radarr (${title1:-$title} ${year1:-$year})" >> "$STARR_RECOMMENDATIONS"
                fi
                echo "❌ DELETE: $path2" >> "$STARR_RECOMMENDATIONS"
                local hf2_lower=$(echo "$has_file2" | tr '[:upper:]' '[:lower:]')
                local m2_lower=$(echo "$monitored2" | tr '[:upper:]' '[:lower:]')
                if [ "$hf2_lower" = "true" ] || [ "$m2_lower" = "true" ]; then
                    echo "   ⚠️  WARNING: This path is TRACKED in Radarr - verify before deleting!" >> "$STARR_RECOMMENDATIONS"
                    delete_tracked=$((delete_tracked + 1))
                fi
                echo "" >> "$STARR_RECOMMENDATIONS"
                ;;
            KEEP2)
                if [ "$reason" = "TRACKED" ] || [ "$reason" = "TRACKED_EXACT" ]; then
                    keep_tracked=$((keep_tracked + 1))
                    delete_untracked=$((delete_untracked + 1))
                elif is_starr_managed "$path2"; then
                    keep_starr=$((keep_starr + 1))
                elif is_external_path "$path2"; then
                    keep_external=$((keep_external + 1))
                fi
                total_size_savings=$((total_size_savings + size1))

                echo "✅ KEEP: $path2" >> "$STARR_RECOMMENDATIONS"
                local hf2_lower=$(echo "$has_file2" | tr '[:upper:]' '[:lower:]')
                local m2_lower=$(echo "$monitored2" | tr '[:upper:]' '[:lower:]')
                if [ "$hf2_lower" = "true" ] || [ "$m2_lower" = "true" ]; then
                    echo "   📌 TRACKED in Radarr (${title2:-$title} ${year2:-$year})" >> "$STARR_RECOMMENDATIONS"
                fi
                echo "❌ DELETE: $path1" >> "$STARR_RECOMMENDATIONS"
                local hf1_lower=$(echo "$has_file1" | tr '[:upper:]' '[:lower:]')
                local m1_lower=$(echo "$monitored1" | tr '[:upper:]' '[:lower:]')
                if [ "$hf1_lower" = "true" ] || [ "$m1_lower" = "true" ]; then
                    echo "   ⚠️  WARNING: This path is TRACKED in Radarr - verify before deleting!" >> "$STARR_RECOMMENDATIONS"
                    delete_tracked=$((delete_tracked + 1))
                fi
                echo "" >> "$STARR_RECOMMENDATIONS"
                ;;
            REVIEW)
                review=$((review + 1))
                echo "⚠️  REVIEW: $title ($year)" >> "$STARR_RECOMMENDATIONS"
                echo "   Location 1: $path1" >> "$STARR_RECOMMENDATIONS"
                local hf1_lower=$(echo "$has_file1" | tr '[:upper:]' '[:lower:]')
                local m1_lower=$(echo "$monitored1" | tr '[:upper:]' '[:lower:]')
                if [ "$hf1_lower" = "true" ] || [ "$m1_lower" = "true" ]; then
                    echo "      📌 TRACKED in Radarr" >> "$STARR_RECOMMENDATIONS"
                fi
                echo "      Quality: $qual1 | Size: ${size1_gb}GB" >> "$STARR_RECOMMENDATIONS"
                echo "   Location 2: $path2" >> "$STARR_RECOMMENDATIONS"
                local hf2_lower=$(echo "$has_file2" | tr '[:upper:]' '[:lower:]')
                local m2_lower=$(echo "$monitored2" | tr '[:upper:]' '[:lower:]')
                if [ "$hf2_lower" = "true" ] || [ "$m2_lower" = "true" ]; then
                    echo "      📌 TRACKED in Radarr" >> "$STARR_RECOMMENDATIONS"
                fi
                echo "      Quality: $qual2 | Size: ${size2_gb}GB" >> "$STARR_RECOMMENDATIONS"
                echo "" >> "$STARR_RECOMMENDATIONS"
                ;;
        esac
    done < "$MOVIES_REPORT"

    local savings_gb=$(echo "scale=2; $total_size_savings / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

    echo "📊 Movie Duplicate Summary:"
    echo "  ✅ Keep Tracked in Radarr: $keep_tracked"
    echo "  ✅ Keep STARR-managed: $keep_starr"
    echo "  ✅ Keep External: $keep_external"
    echo "  ⚠️  Need Review: $review"
    echo "  🚨 WARNING: $delete_tracked tracked items marked for deletion (REVIEW CAREFULLY!)"
    echo "  💾 Potential Space Savings: ${savings_gb}GB"
    echo ""
}

analyze_tv() {
    echo "📺 Analyzing TV Show Duplicates with Sonarr Tracking..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ ! -f "$TV_REPORT" ] || [ ! -s "$TV_REPORT" ]; then
        log_warning "No TV duplicates report found"
        return 1
    fi

    local tracked_file=$(fetch_tracked_series)
    echo ""

    local keep_tracked=0 keep_starr=0 keep_external=0 review=0
    local delete_tracked=0
    local total_size_savings=0

    while IFS='|' read -r title year loc1 path1 qual1 video1 size1 loc2 path2 qual2 video2 size2; do
        local recommendation=$(recommend_series_keep "$loc1" "$path1" "$qual1" "$size1" "$loc2" "$path2" "$qual2" "$size2" "$tracked_file")
        IFS='|' read -r decision reason <<< "$recommendation"

        local size1_gb=$(echo "scale=2; $size1 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
        local size2_gb=$(echo "scale=2; $size2 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

        # Get tracking info
        local track1_info=$(get_series_tracking_info "$path1" "$tracked_file")
        local track2_info=$(get_series_tracking_info "$path2" "$tracked_file")
        IFS='|' read -r monitored1 title1 year1 <<< "$track1_info"
        IFS='|' read -r monitored2 title2 year2 <<< "$track2_info"

        case "$decision" in
            KEEP1)
                if [ "$reason" = "TRACKED" ] || [ "$reason" = "TRACKED_EXACT" ]; then
                    keep_tracked=$((keep_tracked + 1))
                elif is_starr_managed "$path1"; then
                    keep_starr=$((keep_starr + 1))
                elif is_external_path "$path1"; then
                    keep_external=$((keep_external + 1))
                fi
                total_size_savings=$((total_size_savings + size2))

                echo "✅ KEEP: $path1" >> "$STARR_RECOMMENDATIONS"
                local m1_lower=$(echo "$monitored1" | tr '[:upper:]' '[:lower:]')
                if [ "$m1_lower" = "true" ]; then
                    echo "   📌 TRACKED in Sonarr (${title1:-$title} ${year1:-$year})" >> "$STARR_RECOMMENDATIONS"
                fi
                echo "❌ DELETE: $path2" >> "$STARR_RECOMMENDATIONS"
                local m2_lower=$(echo "$monitored2" | tr '[:upper:]' '[:lower:]')
                if [ "$m2_lower" = "true" ]; then
                    echo "   ⚠️  WARNING: This path is TRACKED in Sonarr - verify before deleting!" >> "$STARR_RECOMMENDATIONS"
                    delete_tracked=$((delete_tracked + 1))
                fi
                echo "" >> "$STARR_RECOMMENDATIONS"
                ;;
            KEEP2)
                if [ "$reason" = "TRACKED" ] || [ "$reason" = "TRACKED_EXACT" ]; then
                    keep_tracked=$((keep_tracked + 1))
                elif is_starr_managed "$path2"; then
                    keep_starr=$((keep_starr + 1))
                elif is_external_path "$path2"; then
                    keep_external=$((keep_external + 1))
                fi
                total_size_savings=$((total_size_savings + size1))

                echo "✅ KEEP: $path2" >> "$STARR_RECOMMENDATIONS"
                local m2_lower=$(echo "$monitored2" | tr '[:upper:]' '[:lower:]')
                if [ "$m2_lower" = "true" ]; then
                    echo "   📌 TRACKED in Sonarr (${title2:-$title} ${year2:-$year})" >> "$STARR_RECOMMENDATIONS"
                fi
                echo "❌ DELETE: $path1" >> "$STARR_RECOMMENDATIONS"
                local m1_lower=$(echo "$monitored1" | tr '[:upper:]' '[:lower:]')
                if [ "$m1_lower" = "true" ]; then
                    echo "   ⚠️  WARNING: This path is TRACKED in Sonarr - verify before deleting!" >> "$STARR_RECOMMENDATIONS"
                    delete_tracked=$((delete_tracked + 1))
                fi
                echo "" >> "$STARR_RECOMMENDATIONS"
                ;;
            REVIEW)
                review=$((review + 1))
                echo "⚠️  REVIEW: $title ($year)" >> "$STARR_RECOMMENDATIONS"
                echo "   Location 1: $path1" >> "$STARR_RECOMMENDATIONS"
                local m1_lower=$(echo "$monitored1" | tr '[:upper:]' '[:lower:]')
                if [ "$m1_lower" = "true" ]; then
                    echo "      📌 TRACKED in Sonarr" >> "$STARR_RECOMMENDATIONS"
                fi
                echo "      Quality: $qual1 | Size: ${size1_gb}GB" >> "$STARR_RECOMMENDATIONS"
                echo "   Location 2: $path2" >> "$STARR_RECOMMENDATIONS"
                local m2_lower=$(echo "$monitored2" | tr '[:upper:]' '[:lower:]')
                if [ "$m2_lower" = "true" ]; then
                    echo "      📌 TRACKED in Sonarr" >> "$STARR_RECOMMENDATIONS"
                fi
                echo "      Quality: $qual2 | Size: ${size2_gb}GB" >> "$STARR_RECOMMENDATIONS"
                echo "" >> "$STARR_RECOMMENDATIONS"
                ;;
        esac
    done < "$TV_REPORT"

    local savings_gb=$(echo "scale=2; $total_size_savings / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

    echo "📊 TV Show Duplicate Summary:"
    echo "  ✅ Keep Tracked in Sonarr: $keep_tracked"
    echo "  ✅ Keep STARR-managed: $keep_starr"
    echo "  ✅ Keep External: $keep_external"
    echo "  ⚠️  Need Review: $review"
    echo "  🚨 WARNING: $delete_tracked tracked items marked for deletion (REVIEW CAREFULLY!)"
    echo "  💾 Potential Space Savings: ${savings_gb}GB"
    echo ""
}

# Main
main() {
    if [ ! -f "$MOVIES_REPORT" ] && [ ! -f "$TV_REPORT" ]; then
        echo "❌ No duplicate reports found."
        echo "   Run: bash ~/find_duplicate_media.sh first"
        exit 1
    fi

    analyze_movies
    analyze_tv

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 Detailed recommendations saved to:"
    echo "   $STARR_RECOMMENDATIONS"
    echo ""
    echo "💡 Recommendation Priority:"
    echo "   1. 🥇 TRACKED in Radarr/Sonarr (KEEP - highest priority)"
    echo "   2. 🥈 STARR-managed locations (/data/media, NAS)"
    echo "   3. 🥉 Better organization & quality"
    echo ""
    echo "⚠️  IMPORTANT: Review tracked items marked for deletion!"
    echo "   They may need to be removed from Radarr/Sonarr first."
    echo ""
}

main

