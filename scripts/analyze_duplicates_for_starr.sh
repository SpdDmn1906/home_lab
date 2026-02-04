#!/bin/bash
#
# Analyze Duplicates for STARR Management
# Provides recommendations based on STARR app management goals
# - Prioritizes STARR-managed locations (/data/media)
# - Recommends keeping organized, properly-named files
# - Considers quality and size
#

set -e

# STARR-managed locations (primary)
STARR_MOVIES="/data/media/Movies"
STARR_KIDS_MOVIES="/data/media/Movies - Kids"
STARR_TV="/data/media/TV Shows"
STARR_KIDS_TV="/data/media/TV Shows - Kids"

# Non-STARR locations (secondary/legacy)
EXTERNAL_MOVIES="/external/media/Movies"
EXTERNAL_KIDS_MOVIES="/external/media/Kids Movies"
EXTERNAL_TV="/external/media/TV"
EXTERNAL_KIDS_TV="/external/media/Kids TV"

# NAS direct paths (same as /data but different mount)
NAS_MOVIES="/home/youruser/synology/Media/Movies"
NAS_KIDS_MOVIES="/home/youruser/synology/Media/Movies - Kids"
NAS_TV="/home/youruser/synology/Media/TV Shows"
NAS_KIDS_TV="/home/youruser/synology/Media/TV Shows - Kids"

REPORT_FILE="/tmp/duplicate_starr_recommendations.txt"
MOVIES_REPORT="/tmp/duplicate_movies_report.txt"
TV_REPORT="/tmp/duplicate_tv_report.txt"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     📊 DUPLICATE ANALYSIS FOR STARR MANAGEMENT               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Function to check if path is STARR-managed
# /data/media is bind mount to NAS, so NAS paths are also STARR-managed
is_starr_managed() {
    local path="$1"
    if [[ "$path" == /data/media/* ]] || [[ "$path" == /home/youruser/synology/Media/* ]]; then
        return 0  # STARR-managed (NAS or /data)
    else
        return 1  # Not STARR-managed
    fi
}

# Function to check if path is NAS (same storage as /data, STARR-managed)
is_nas_path() {
    local path="$1"
    if [[ "$path" == /home/youruser/synology/Media/* ]] || [[ "$path" == /data/media/* ]]; then
        return 0  # NAS path (STARR-managed)
    else
        return 1  # Not NAS
    fi
}

# Function to check if path is external/USB
is_external_path() {
    local path="$1"
    if [[ "$path" == /external/media/* ]]; then
        return 0  # External/USB
    else
        return 1  # Not external
    fi
}

# Function to get file organization score (higher = better organized)
get_organization_score() {
    local path="$1"
    local basename=$(basename "$path")

    # Check for proper folder structure (Movie Name (Year)/file.mkv)
    if echo "$path" | grep -qE "/[^/]+ \([0-9]{4}\)"; then
        echo "10"  # Properly organized
    elif echo "$basename" | grep -qE "^[A-Za-z].*\([0-9]{4}\)"; then
        echo "8"   # Good naming
    elif echo "$basename" | grep -qE "[0-9]{4}"; then
        echo "6"   # Has year
    else
        echo "4"   # Poor organization
    fi
}

# Function to recommend which duplicate to keep
recommend_keep() {
    local loc1="$1" path1="$2" qual1="$3" size1="$4"
    local loc2="$5" path2="$6" qual2="$7" size2="$8"

    local starr1=0 starr2=0 nas1=0 nas2=0 ext1=0 ext2=0
    local org1 org2

    # Check location types (STARR-managed gets highest priority)
    if is_starr_managed "$path1"; then
        starr1=10  # STARR-managed (NAS or /data)
        nas1=0     # Don't double-count
    elif is_nas_path "$path1"; then
        nas1=5     # NAS but not in standard STARR path
    fi

    if is_starr_managed "$path2"; then
        starr2=10  # STARR-managed (NAS or /data)
        nas2=0     # Don't double-count
    elif is_nas_path "$path2"; then
        nas2=5     # NAS but not in standard STARR path
    fi

    if is_external_path "$path1"; then ext1=1; fi
    if is_external_path "$path2"; then ext2=1; fi

    # Get organization scores
    org1=$(get_organization_score "$path1")
    org2=$(get_organization_score "$path2")

    # Quality scores (higher = better)
    local qual_score1=5 qual_score2=5
    case "$qual1" in
        BLURAY) qual_score1=10 ;;
        WEB) qual_score1=8 ;;
        DVD) qual_score1=6 ;;
        LOW) qual_score1=2 ;;
        UNKNOWN) qual_score1=5 ;;
    esac
    case "$qual2" in
        BLURAY) qual_score2=10 ;;
        WEB) qual_score2=8 ;;
        DVD) qual_score2=6 ;;
        LOW) qual_score2=2 ;;
        UNKNOWN) qual_score2=5 ;;
    esac

    # Size preference (larger usually better, but not if low quality)
    local size_score1=5 size_score2=5
    if [ "$qual1" != "LOW" ] && (( $(echo "$size1 > $size2" | bc -l 2>/dev/null || echo "0") )); then
        size_score1=7
        size_score2=3
    elif [ "$qual2" != "LOW" ] && (( $(echo "$size2 > $size1" | bc -l 2>/dev/null || echo "0") )); then
        size_score1=3
        size_score2=7
    fi

    # Calculate total scores
    local score1=$((starr1 + nas1 - ext1 + org1 + qual_score1 + size_score1))
    local score2=$((starr2 + nas2 - ext2 + org2 + qual_score2 + size_score2))

    if [ "$score1" -gt "$score2" ]; then
        echo "KEEP1"
    elif [ "$score2" -gt "$score1" ]; then
        echo "KEEP2"
    else
        echo "REVIEW"  # Tie - needs manual review
    fi
}

# Analyze movies
analyze_movies() {
    echo "🎬 Analyzing Movie Duplicates..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ ! -f "$MOVIES_REPORT" ] || [ ! -s "$MOVIES_REPORT" ]; then
        echo "⚠️  No movie duplicates report found. Run find_duplicate_media.sh first."
        return 1
    fi

    local keep_starr=0 keep_external=0 keep_nas=0 review=0
    local total_size_savings=0

    : > "$REPORT_FILE"

    while IFS='|' read -r title year loc1 path1 qual1 video1 size1 loc2 path2 qual2 video2 size2; do
        local recommendation=$(recommend_keep "$loc1" "$path1" "$qual1" "$size1" "$loc2" "$path2" "$qual2" "$size2")
        local size1_gb=$(echo "scale=2; $size1 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
        local size2_gb=$(echo "scale=2; $size2 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

        case "$recommendation" in
            KEEP1)
                if is_starr_managed "$path1"; then
                    keep_starr=$((keep_starr + 1))
                elif is_external_path "$path1"; then
                    keep_external=$((keep_external + 1))
                else
                    keep_nas=$((keep_nas + 1))
                fi
                total_size_savings=$((total_size_savings + size2))
                echo "✅ KEEP: $path1" >> "$REPORT_FILE"
                echo "❌ DELETE: $path2" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                ;;
            KEEP2)
                if is_starr_managed "$path2"; then
                    keep_starr=$((keep_starr + 1))
                elif is_external_path "$path2"; then
                    keep_external=$((keep_external + 1))
                else
                    keep_nas=$((keep_nas + 1))
                fi
                total_size_savings=$((total_size_savings + size1))
                echo "✅ KEEP: $path2" >> "$REPORT_FILE"
                echo "❌ DELETE: $path1" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                ;;
            REVIEW)
                review=$((review + 1))
                echo "⚠️  REVIEW: $title ($year)" >> "$REPORT_FILE"
                echo "   Location 1: $path1 ($qual1, ${size1_gb}GB)" >> "$REPORT_FILE"
                echo "   Location 2: $path2 ($qual2, ${size2_gb}GB)" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                ;;
        esac
    done < "$MOVIES_REPORT"

    local savings_gb=$(echo "scale=2; $total_size_savings / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

    echo "📊 Movie Duplicate Summary:"
    echo "  ✅ Keep STARR-managed: $keep_starr"
    echo "  ✅ Keep NAS (non-STARR): $keep_nas"
    echo "  ✅ Keep External: $keep_external"
    echo "  ⚠️  Need Review: $review"
    echo "  💾 Potential Space Savings: ${savings_gb}GB"
    echo ""
}

# Analyze TV shows
analyze_tv() {
    echo "📺 Analyzing TV Show Duplicates..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ ! -f "$TV_REPORT" ] || [ ! -s "$TV_REPORT" ]; then
        echo "⚠️  No TV duplicates report found. Run find_duplicate_media.sh first."
        return 1
    fi

    local keep_starr=0 keep_external=0 keep_nas=0 review=0
    local total_size_savings=0

    while IFS='|' read -r title year loc1 path1 qual1 video1 size1 loc2 path2 qual2 video2 size2; do
        local recommendation=$(recommend_keep "$loc1" "$path1" "$qual1" "$size1" "$loc2" "$path2" "$qual2" "$size2")

        case "$recommendation" in
            KEEP1)
                if is_starr_managed "$path1"; then
                    keep_starr=$((keep_starr + 1))
                elif is_external_path "$path1"; then
                    keep_external=$((keep_external + 1))
                else
                    keep_nas=$((keep_nas + 1))
                fi
                total_size_savings=$((total_size_savings + size2))
                ;;
            KEEP2)
                if is_starr_managed "$path2"; then
                    keep_starr=$((keep_starr + 1))
                elif is_external_path "$path2"; then
                    keep_external=$((keep_external + 1))
                else
                    keep_nas=$((keep_nas + 1))
                fi
                total_size_savings=$((total_size_savings + size1))
                ;;
            REVIEW)
                review=$((review + 1))
                ;;
        esac
    done < "$TV_REPORT"

    local savings_gb=$(echo "scale=2; $total_size_savings / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")

    echo "📊 TV Show Duplicate Summary:"
    echo "  ✅ Keep STARR-managed: $keep_starr"
    echo "  ✅ Keep NAS (non-STARR): $keep_nas"
    echo "  ✅ Keep External: $keep_external"
    echo "  ⚠️  Need Review: $review"
    echo "  💾 Potential Space Savings: ${savings_gb}GB"
    echo ""
}

# Main execution
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
    echo "   $REPORT_FILE"
    echo ""
    echo "💡 STARR Management Principles Applied:"
    echo "   1. ✅ Prioritize /data/media (STARR-managed locations)"
    echo "   2. ✅ Prefer properly organized folders (Movie Name (Year))"
    echo "   3. ✅ Favor higher quality (Bluray > Web > DVD > Low)"
    echo "   4. ✅ Prefer larger file sizes (when quality is same)"
    echo "   5. ⚠️  External/USB locations deprioritized (less managed)"
    echo ""
}

main

