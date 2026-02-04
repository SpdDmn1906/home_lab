#!/bin/bash
#
# Run Quarantine Script in Screen Session
# Prevents timeouts and allows resuming if interrupted
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUARANTINE_SCRIPT="${SCRIPT_DIR}/quarantine_tracked_duplicates.sh"
SCREEN_NAME="quarantine_duplicates"
LOG_FILE="/tmp/quarantine_screen.log"

# Check if screen is installed
if ! command -v screen &> /dev/null; then
    echo "❌ screen is not installed. Installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y screen
    elif command -v yum &> /dev/null; then
        sudo yum install -y screen
    else
        echo "❌ Cannot install screen automatically. Please install it manually."
        exit 1
    fi
fi

# Check if script exists
if [ ! -f "$QUARANTINE_SCRIPT" ]; then
    echo "❌ Quarantine script not found: $QUARANTINE_SCRIPT"
    exit 1
fi

# Make script executable
chmod +x "$QUARANTINE_SCRIPT"

# Function to check if screen session exists
screen_exists() {
    screen -list | grep -q "$SCREEN_NAME"
}

# Function to attach to existing session
attach_session() {
    echo "📺 Attaching to existing screen session: $SCREEN_NAME"
    echo "   Use Ctrl+A then D to detach"
    screen -r "$SCREEN_NAME"
}

# Function to create new session
create_session() {
    echo "🆕 Creating new screen session: $SCREEN_NAME"
    screen -dmS "$SCREEN_NAME" bash -c "$QUARANTINE_SCRIPT 2>&1 | tee $LOG_FILE; echo ''; echo 'Press Enter to close this window...'; read"
    sleep 2
    if screen_exists; then
        echo "✅ Screen session created successfully"
        echo "📺 Attach with: screen -r $SCREEN_NAME"
        echo "📝 View log with: tail -f $LOG_FILE"
        echo ""
        read -p "Attach to session now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            attach_session
        fi
    else
        echo "❌ Failed to create screen session"
        exit 1
    fi
}

# Main logic
if screen_exists; then
    echo "⚠️  Screen session '$SCREEN_NAME' already exists"
    echo ""
    echo "Options:"
    echo "  1. Attach to existing session"
    echo "  2. Kill existing and create new"
    echo "  3. Exit"
    echo ""
    read -p "Choose option (1-3): " -n 1 -r
    echo
    case $REPLY in
        1)
            attach_session
            ;;
        2)
            echo "🛑 Killing existing session..."
            screen -S "$SCREEN_NAME" -X quit
            sleep 1
            create_session
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Exiting..."
            exit 1
            ;;
    esac
else
    create_session
fi

