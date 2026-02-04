#!/bin/bash
#
# Delete Corrupted and Low-Quality Duplicate Files
# Based on duplicate detection scan results
#
# Usage: ./delete_corrupted_and_low_quality.sh [--dry-run]
#   --dry-run: Show what would be deleted without actually deleting

set -e

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE - No files will be deleted"
    echo ""
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      🗑️  DELETE CORRUPTED & LOW-QUALITY FILES                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Arrays to store files to delete
CORRUPTED_FILES=()
LOW_QUALITY_FILES=()

# Function to add file to deletion list
add_to_delete() {
    local file="$1"
    local reason="$2"

    if [ "$reason" = "corrupted" ]; then
        CORRUPTED_FILES+=("$file")
    elif [ "$reason" = "low_quality" ]; then
        LOW_QUALITY_FILES+=("$file")
    fi
}

# Function to delete file or directory
delete_path() {
    local path="$1"
    local reason="$2"

    if [ ! -e "$path" ]; then
        echo -e "  ${YELLOW}⚠️  Path not found: $path${NC}"
        return 1
    fi

    if [ -f "$path" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[DRY RUN] Would delete file:${NC} $path"
        else
            rm -f "$path" && echo -e "  ${GREEN}✅ Deleted file:${NC} $(basename "$path")"
        fi
    elif [ -d "$path" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[DRY RUN] Would delete directory:${NC} $path"
        else
            rm -rf "$path" && echo -e "  ${GREEN}✅ Deleted directory:${NC} $(basename "$path")"
        fi
    fi

    return 0
}

# 1. Corrupted files from scan
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔴 STEP 1: CORRUPTED FILES (Must Delete)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# The Wild Robot (2024) - CORRUPTED (5,104 errors)
WILD_ROBOT_NAS="/home/youruser/synology/Media/Movies/The Wild Robot (2024) [1080p] [WEBRip] [5.1] [YTS.MX]"
if [ -d "$WILD_ROBOT_NAS" ]; then
    echo "📁 The Wild Robot (2024) - NAS Movies"
    echo "   Path: $WILD_ROBOT_NAS"
    echo "   Reason: CORRUPTED (5,104 errors)"
    delete_path "$WILD_ROBOT_NAS" "corrupted"
    echo ""
fi

# Z-O-M-B-I-E-S 3 (2022) - CORRUPTED (5,414 errors)
ZOMBIES3_NAS="/home/youruser/synology/Media/Movies - Kids/Z-O-M-B-I-E-S 3 (2022)"
if [ -d "$ZOMBIES3_NAS" ]; then
    echo "📁 Z-O-M-B-I-E-S 3 (2022) - NAS Kids Movies"
    echo "   Path: $ZOMBIES3_NAS"
    echo "   Reason: CORRUPTED (5,414 errors)"
    delete_path "$ZOMBIES3_NAS" "corrupted"
    echo ""
fi

# 2. Low-quality duplicates from duplicate scan report
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔴 STEP 2: LOW-QUALITY DUPLICATES (CAM/TS Versions)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Read from duplicate report if it exists
if [ -f /tmp/duplicate_movies_report.txt ]; then
    echo "Reading from duplicate scan report..."
    echo ""

    while IFS='|' read -r title year loc1 path1 qual1 video1 size1 loc2 path2 qual2 video2 size2; do
        if [ "$qual1" = "LOW" ]; then
            echo "📁 $title ($year)"
            echo "   Location: $loc1"
            echo "   Quality: LOW (CAM/TS/HDTS)"
            echo "   Path: $path1"
            delete_path "$path1" "low_quality"

            # Also delete empty parent directory if it's a folder
            parent_dir=$(dirname "$path1")
            if [ -d "$parent_dir" ] && [ "$(find "$parent_dir" -mindepth 1 2>/dev/null | wc -l)" -eq 0 ]; then
                delete_path "$parent_dir" "low_quality"
            fi
            echo ""
        fi

        if [ "$qual2" = "LOW" ]; then
            echo "📁 $title ($year)"
            echo "   Location: $loc2"
            echo "   Quality: LOW (CAM/TS/HDTS)"
            echo "   Path: $path2"
            delete_path "$path2" "low_quality"

            # Also delete empty parent directory if it's a folder
            parent_dir=$(dirname "$path2")
            if [ -d "$parent_dir" ] && [ "$(find "$parent_dir" -mindepth 1 2>/dev/null | wc -l)" -eq 0 ]; then
                delete_path "$parent_dir" "low_quality"
            fi
            echo ""
        fi
    done < /tmp/duplicate_movies_report.txt
else
    echo "⚠️  Duplicate report not found. Using hardcoded list..."
    echo ""

    # Hardcoded list from scan results
    LOW_QUALITY_PATHS=(
        "/home/youruser/synology/Media/Movies/Black Panther Wakanda Forever (2022) [1080p] [BluRay] [5.1] [YTS.MX]"
        "/home/youruser/synology/Media/Movies/Chicken Run Dawn Of The Nugget (2023) [1080p] [WEBRip] [5.1] [YTS.MX]"
        "/home/youruser/synology/Media/Movies - Kids/Chicken Run Dawn Of The Nugget (2023) [1080p] [WEBRip] [5.1] [YTS.MX]"
        "/home/youruser/synology/Media/Movies - Kids/Elemental (2023) V3 1080p HDTS 2.5GB x264 AAC.mp4"
        "/home/youruser/synology/Media/Movies - Kids/Elemental (2023) V3 1080p HDTS x264 AAC - NOGRP.mp4"
        "/home/youruser/synology/Media/Movies/Mighty Morphin Power Rangers The Movie (1995) [1080p] [BluRay] [5.1] [YTS.MX]"
        "/external/media/Kids Movies/Puss in Boots (2011) (1080p BDRip x265 10bit EAC3 5.1 - r0b0t) [TAoE].mkv"
        "/external/media/Kids Movies/Puss in Boots (2011)"
        "/external/media/Kids Movies/The Grinch (2018) [BluRay] [1080p] [YTS.AM]"
        "/home/youruser/synology/Media/Movies - Kids/The Little Mermaid (2023) V2 1080p TS x264 AAC - HushRips.mp4"
        "/home/youruser/synology/Media/Movies/The.Mitchells.vs.The.Machines.2021.1080p.WEB.h264-RUMOUR[rarbg]"
        "/home/youruser/synology/Media/Movies - Kids/The.Mitchells.vs.The.Machines.2021.1080p.WEB.h264-RUMOUR[rarbg]"
        "/home/youruser/synology/Media/Movies/The Wild Robot (2024) [1080p] [WEBRip] [5.1] [YTS.MX]"
        "/home/youruser/synology/Media/Movies - Kids/The Wild Robot (2024) [1080p] [WEBRip] [5.1] [YTS.MX]"
        "/home/youruser/synology/Media/Movies/Transformers One (2024) [1080p] [WEBRip] [5.1] [YTS.MX]"
        "/home/youruser/synology/Media/Movies - Kids/Transformers One (2024) [1080p] [WEBRip] [5.1] [YTS.MX]"
    )

    for path in "${LOW_QUALITY_PATHS[@]}"; do
        if [ -e "$path" ]; then
            echo "📁 $(basename "$path")"
            echo "   Path: $path"
            echo "   Quality: LOW (CAM/TS/HDTS)"
            delete_path "$path" "low_quality"

            # Delete empty parent if folder
            parent_dir=$(dirname "$path")
            if [ -d "$parent_dir" ] && [ "$(find "$parent_dir" -mindepth 1 2>/dev/null | wc -l)" -eq 0 ]; then
                delete_path "$parent_dir" "low_quality"
            fi
            echo ""
        fi
    done
fi

# 3. Lightyear HQCAM duplicate
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔴 STEP 3: LIGHTYEAR HQCAM DUPLICATE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

LIGHTYEAR_CAM="/home/youruser/synology/Media/Movies - Kids/Lightyear (2022) ENG 1080p HQCAM x264 AAC - HushRips.mkv"
if [ -f "$LIGHTYEAR_CAM" ]; then
    echo "📁 Lightyear (2022) - HQCAM Version"
    echo "   Path: $LIGHTYEAR_CAM"
    echo "   Reason: LOW quality CAM recording (keep Bluray version)"
    delete_path "$LIGHTYEAR_CAM" "low_quality"
    echo ""
else
    echo "⚠️  Lightyear CAM file not found (may already be deleted)"
    echo ""
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

corrupted_count=${#CORRUPTED_FILES[@]}
low_quality_count=${#LOW_QUALITY_FILES[@]}
total=$((corrupted_count + low_quality_count))

if [ "$DRY_RUN" = true ]; then
    echo "  ${YELLOW}DRY RUN - No files deleted${NC}"
    echo "  Corrupted files to delete: $corrupted_count"
    echo "  Low-quality files to delete: $low_quality_count"
    echo "  Total: $total files"
else
    echo "  ${GREEN}✅ Deletion complete!${NC}"
    echo "  Corrupted files deleted: $corrupted_count"
    echo "  Low-quality files deleted: $low_quality_count"
    echo "  Total: $total files"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              ✅ DELETION COMPLETE                               ║"
echo "╚════════════════════════════════════════════════════════════════╝"

