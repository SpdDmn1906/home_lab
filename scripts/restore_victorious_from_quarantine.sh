#!/bin/bash
# Restore Victorious files from quarantine
# Date: 2026-01-09
# Reason: Files were incorrectly marked as CORRUPT but play correctly

set -euo pipefail

QUARANTINE_ROOT="/external/media/_quarantine/20260109_132000"
SOURCE="${QUARANTINE_ROOT}/external/media/Kids TV/Victorious (2010)"
DEST="/external/media/Kids TV/Victorious (2010)"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Restoring Victorious Files from Quarantine                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Source: ${SOURCE}"
echo "Dest: ${DEST}"
echo ""

# Check if source exists
if [ ! -d "$SOURCE" ]; then
    echo "❌ ERROR: Quarantine directory not found: $SOURCE"
    echo ""
    echo "Checking for alternative locations..."
    find /external/media/_quarantine -name "Victorious*" -type d 2>/dev/null | head -5 || echo "   No Victorious directory found in quarantine"
    exit 1
fi

# Count files in quarantine
quarantine_count=$(find "$SOURCE" -type f 2>/dev/null | wc -l)
echo "Found $quarantine_count files in quarantine"
echo ""

# Create destination directory if it doesn't exist
mkdir -p "$(dirname "$DEST")"

# Check if destination already exists
if [ -d "$DEST" ]; then
    echo "⚠️  WARNING: Destination directory already exists: $DEST"
    echo "Checking if it's empty or has existing files..."
    dest_count=$(find "$DEST" -type f 2>/dev/null | wc -l)
    if [ "$dest_count" -gt 0 ]; then
        echo "   Found $dest_count files in destination."
        echo "   This restore will overwrite/move files back."
        echo ""
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
fi

echo ""
echo "Moving files back to original location..."
if mv -v "$SOURCE" "$DEST"; then
    echo ""
    echo "✅ Successfully restored Victorious files!"
    echo "Location: $DEST"

    # Verify files are restored
    restored_count=$(find "$DEST" -type f 2>/dev/null | wc -l)
    echo "   Restored $restored_count files"
    echo ""
    echo "Next steps:"
    echo "  1. Verify files play correctly in Plex"
    echo "  2. If tracked in Sonarr, it may detect the files and mark them as available"
    echo "  3. You may want to trigger a Sonarr refresh for this series"
    echo ""
else
    echo "❌ ERROR: Failed to move directory"
    exit 1
fi

