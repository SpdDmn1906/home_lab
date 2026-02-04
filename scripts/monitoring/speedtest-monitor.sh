#!/bin/bash
# Speedtest Monitoring Script
# Runs periodic speedtests and logs results

set -euo pipefail

LOG_FILE="${LOG_FILE:-/tmp/speedtest-$(date +%Y%m%d).log}"
INTERVAL="${INTERVAL:-3600}"  # Default: 1 hour

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_speedtest() {
    if ! command -v speedtest-cli &> /dev/null; then
        log "ERROR: speedtest-cli not installed. Install with: pip install speedtest-cli"
        exit 1
    fi
}

run_speedtest() {
    log "Running speedtest..."
    speedtest-cli --simple | tee -a "$LOG_FILE"
    echo "---" | tee -a "$LOG_FILE"
}

main() {
    log "Starting speedtest monitoring (interval: ${INTERVAL}s)"
    check_speedtest

    while true; do
        run_speedtest
        log "Waiting ${INTERVAL} seconds until next test..."
        sleep "$INTERVAL"
    done
}

# Run once if called directly, or continuously if --daemon flag
if [ "${1:-}" == "--daemon" ]; then
    main
else
    check_speedtest
    run_speedtest
fi



