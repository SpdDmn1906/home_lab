#!/bin/bash

echo "🗂️ SIMPLIFIED QUARANTINE PROCESS"
echo "================================"

# Configuration
QUARANTINE_BASE="/data/media/.quarantine"
LOG_FILE="$QUARANTINE_BASE/quarantine.log"
MAX_PARALLEL=4
PROCESSED=0
SUCCESS=0
ERRORS=0

# Create quarantine directory if it doesn't exist
mkdir -p "$QUARANTINE_BASE/Movies" "$QUARANTINE_BASE/TV Shows"

echo "Processing recommendations..."

# Process each recommendation
while IFS="|" read -r action path1 path2 title year quality1 quality2 score1 score2; do
    ((PROCESSED++))

    case "$action" in
        "KEEP1")
            # Move path2 to quarantine (keep path1)
            SOURCE_PATH="$path2"
            ;;
        "KEEP2")
            # Move path1 to quarantine (keep path2)
            SOURCE_PATH="$path1"
            ;;
        "REVIEW")
            # Skip items that need manual review
            echo "⏭️  Skipping manual review: $title ($year)"
            continue
            ;;
        *)
            echo "⚠️  Unknown action: $action for $title"
            continue
            ;;
    esac

    # Determine media type and quarantine subdir
    if [[ "$SOURCE_PATH" == *"/TV"* ]] || [[ "$SOURCE_PATH" == *"/Kids TV"* ]]; then
        QUARANTINE_SUBDIR="TV Shows"
    else
        QUARANTINE_SUBDIR="Movies"
    fi

    # Create unique quarantine path to avoid conflicts
    BASENAME=$(basename "$SOURCE_PATH")
    COUNTER=1
    QUARANTINE_PATH="$QUARANTINE_BASE/$QUARANTINE_SUBDIR/$BASENAME"
    while [ -e "$QUARANTINE_PATH" ]; do
        QUARANTINE_PATH="$QUARANTINE_BASE/$QUARANTINE_SUBDIR/${BASENAME}_$COUNTER"
        ((COUNTER++))
    done

    # Move to quarantine
    if mv "$SOURCE_PATH" "$QUARANTINE_PATH" 2>/dev/null; then
        ((SUCCESS++))
        echo "[$(date)] SUCCESS - Moved to quarantine: $SOURCE_PATH -> $QUARANTINE_PATH" >> "$LOG_FILE"
        echo "✅ Quarantined: $BASENAME"
    else
        ((ERRORS++))
        echo "[$(date)] ERROR - Failed to quarantine: $SOURCE_PATH" >> "$LOG_FILE"
        echo "❌ Failed to quarantine: $BASENAME"
    fi

    # Progress update
    if [ $((PROCESSED % 10)) -eq 0 ]; then
        echo "Progress: $PROCESSED items processed..."
    fi

done < /tmp/simple_duplicate_recommendations.txt

echo ""
echo "✅ QUARANTINE COMPLETE"
echo "======================"
echo "Total processed: $PROCESSED"
echo "Successfully quarantined: $SUCCESS"
echo "Errors: $ERRORS"
echo "Skipped (manual review): $(grep -c "REVIEW" /tmp/simple_duplicate_recommendations.txt)"
echo ""
echo "Quarantine location: $QUARANTINE_BASE"
echo "Log file: $LOG_FILE"
