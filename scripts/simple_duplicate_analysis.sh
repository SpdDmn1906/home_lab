#!/bin/bash

echo "📊 SIMPLE DUPLICATE ANALYSIS (No STARR Required)"
echo "================================================"

# Quality scoring (higher = better)
declare -A QUALITY_SCORES=(
    ["BLURAY"]=100
    ["DVD"]=80
    ["WEB"]=60
    ["HDTS"]=40
    ["TS"]=30
    ["CAM"]=20
    ["LOW"]=10
    ["UNKNOWN"]=50
)

# Location scoring (higher = better)
declare -A LOCATION_SCORES=(
    ["/data/media"]=100
    ["/home/youruser/synology"]=80
    ["/external/media"]=60
)

OUTPUT_FILE="/tmp/simple_duplicate_recommendations.txt"
echo "" > "$OUTPUT_FILE"

echo "Processing duplicate pairs..."
COUNT=0

while IFS="|" read -r title year loc1 path1 quality1 file1 size1 loc2 path2 quality2 file2 size2; do
    ((COUNT++))

    # Get scores
    QUAL1_SCORE=${QUALITY_SCORES[$quality1]:-50}
    QUAL2_SCORE=${QUALITY_SCORES[$quality2]:-50}
    LOC1_SCORE=${LOCATION_SCORES[$loc1]:-0}
    LOC2_SCORE=${LOCATION_SCORES[$loc2]:-0}

    # Calculate total scores
    SCORE1=$((QUAL1_SCORE + LOC1_SCORE))
    SCORE2=$((QUAL2_SCORE + LOC2_SCORE))

    # Size bonus (prefer larger files of same quality)
    if [ "$QUAL1_SCORE" -eq "$QUAL2_SCORE" ]; then
        if [ "$size1" -gt "$size2" ]; then
            SCORE1=$((SCORE1 + 5))
        elif [ "$size2" -gt "$size1" ]; then
            SCORE2=$((SCORE2 + 5))
        fi
    fi

    # Make recommendation
    if [ "$SCORE1" -gt "$SCORE2" ]; then
        ACTION="KEEP1"
        KEEP_PATH="$path1"
        DELETE_PATH="$path2"
    elif [ "$SCORE2" -gt "$SCORE1" ]; then
        ACTION="KEEP2"
        KEEP_PATH="$path2"
        DELETE_PATH="$path1"
    else
        ACTION="REVIEW"
        KEEP_PATH="$path1"
        DELETE_PATH="$path2"
    fi

    # Output recommendation
    echo "$ACTION|$KEEP_PATH|$DELETE_PATH|$title|$year|$quality1|$quality2|$SCORE1|$SCORE2" >> "$OUTPUT_FILE"

    if [ $((COUNT % 10)) -eq 0 ]; then
        echo "Processed $COUNT duplicates..."
    fi

done < /tmp/duplicate_scan_results.txt

echo "✅ Analysis complete: $COUNT recommendations generated"
echo "Results saved to: $OUTPUT_FILE"

# Summary
KEEP1_COUNT=$(grep -c "KEEP1" "$OUTPUT_FILE")
KEEP2_COUNT=$(grep -c "KEEP2" "$OUTPUT_FILE")
REVIEW_COUNT=$(grep -c "REVIEW" "$OUTPUT_FILE")

echo ""
echo "SUMMARY:"
echo "========"
echo "Total duplicates: $COUNT"
echo "Keep first file: $KEEP1_COUNT"
echo "Keep second file: $KEEP2_COUNT"
echo "Manual review: $REVIEW_COUNT"
echo ""
echo "Ready for quarantine process!"
