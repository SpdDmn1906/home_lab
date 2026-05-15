#!/bin/bash
# Plex Fortress Guard
# Blocks plex.tv via iptables when it returns error responses (503, etc.)
# so Plex sees timeouts and falls back to local cache instead of losing
# managed user profiles.

set -euo pipefail

# --- Config ---
PLEX_DOMAINS=("plex.tv" "app.plex.tv" "clients.plex.tv")
HEALTH_URL="https://plex.tv"
CURL_CONNECT_TIMEOUT=3
CURL_MAX_TIMEOUT=8
IPTABLES_TAG="plex-fortress-guard"
STATE_FILE="/var/run/plex-fortress-guard.state"
LOG_FILE="/var/log/homelab/plex-fortress-guard.log"
METRICS_DIR="/var/lib/node_exporter/textfile_collector"
DRY_RUN=false

# --- Colors & logging ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

_log() { local color="$1" prefix="$2"; shift 2; echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] ${prefix}${NC} $*" | tee -a "$LOG_FILE"; }
log()     { _log "$BLUE"   "INFO"  "$@"; }
success() { _log "$GREEN"  "OK"    "$@"; }
warning() { _log "$YELLOW" "WARN"  "$@"; }
error()   { _log "$RED"    "ERROR" "$@"; }

# --- State tracking ---
read_state()  { cat "$STATE_FILE" 2>/dev/null || echo "UNKNOWN"; }
write_state() { echo "$1" > "$STATE_FILE"; }

# --- Health check ---
# temporarily lifts all blocks so we can probe through our own firewall.
# window is <5s (curl timeout) -- harmless, Plex won't re-auth that fast.
check_health() {
    local blocked
    blocked=$(get_blocked_ips)

    # lift blocks for the probe
    for ip in $blocked; do
        iptables -D OUTPUT -d "$ip" -j DROP -m comment --comment "$IPTABLES_TAG" 2>/dev/null || true
    done

    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" -L \
        --connect-timeout "$CURL_CONNECT_TIMEOUT" \
        --max-time "$CURL_MAX_TIMEOUT" \
        "$HEALTH_URL" 2>/dev/null) || true

    # re-block unless plex.tv is healthy again (2xx or 3xx = healthy)
    if [[ ! "$code" =~ ^[23] ]]; then
        for ip in $blocked; do
            iptables -A OUTPUT -d "$ip" -j DROP -m comment --comment "$IPTABLES_TAG" 2>/dev/null || true
        done
    fi

    if [[ -z "$code" || "$code" == "000" ]]; then
        echo "UNREACHABLE"
    elif [[ "$code" =~ ^[23] ]]; then
        echo "HEALTHY"
    else
        echo "DEGRADED"
    fi
}

# --- IP resolution ---
resolve_ips() {
    local ips=()
    for domain in "${PLEX_DOMAINS[@]}"; do
        while IFS= read -r ip; do
            [[ -n "$ip" ]] && ips+=("$ip")
        done < <(dig +short A "$domain" 2>/dev/null | grep -E '^[0-9]+\.' || true)
    done
    printf '%s\n' "${ips[@]}" | sort -u
}

# --- iptables helpers ---
get_blocked_ips() {
    iptables-save 2>/dev/null \
        | grep -F "$IPTABLES_TAG" \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?' \
        | sed 's|/32||' \
        | sort -u || true
}

run_ipt() {
    if $DRY_RUN; then
        log "[DRY-RUN] iptables $*"
    else
        iptables "$@"
    fi
}

block_ips() {
    local resolved blocked
    resolved=$(resolve_ips)

    if [[ -z "$resolved" ]]; then
        warning "DNS returned no IPs -- keeping existing rules"
        return
    fi

    blocked=$(get_blocked_ips)

    # remove stale
    for ip in $blocked; do
        echo "$resolved" | grep -qF "$ip" || {
            run_ipt -D OUTPUT -d "$ip" -j DROP -m comment --comment "$IPTABLES_TAG" 2>/dev/null || true
            log "Removed stale rule: $ip"
        }
    done

    # add missing
    for ip in $resolved; do
        echo "$blocked" | grep -qF "$ip" || {
            run_ipt -A OUTPUT -d "$ip" -j DROP -m comment --comment "$IPTABLES_TAG"
            log "Blocked: $ip"
        }
    done
}

unblock_all() {
    # loop-delete since multiple rules may exist
    while iptables-save 2>/dev/null | grep -qF "$IPTABLES_TAG"; do
        local ip
        ip=$(iptables-save 2>/dev/null | grep -F "$IPTABLES_TAG" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        [[ -z "$ip" ]] && break
        run_ipt -D OUTPUT -d "$ip" -j DROP -m comment --comment "$IPTABLES_TAG" 2>/dev/null || break
        log "Unblocked: $ip"
    done
}

# --- Prometheus metrics ---
write_metrics() {
    [[ -d "$METRICS_DIR" ]] || return 0
    local state_val blocked_count
    case "$1" in
        HEALTHY)     state_val=0 ;;
        DEGRADED)    state_val=1 ;;
        UNREACHABLE) state_val=2 ;;
        *)           state_val=3 ;;
    esac
    blocked_count=$(get_blocked_ips | wc -l)

    cat > "$METRICS_DIR/plex_fortress_guard.prom" <<EOF
# HELP plex_fortress_guard_state 0=healthy, 1=degraded, 2=unreachable
# TYPE plex_fortress_guard_state gauge
plex_fortress_guard_state $state_val
# HELP plex_fortress_guard_blocked_ips Number of blocked plex.tv IPs
# TYPE plex_fortress_guard_blocked_ips gauge
plex_fortress_guard_blocked_ips $blocked_count
# HELP plex_fortress_guard_last_check Unix timestamp of last check
# TYPE plex_fortress_guard_last_check gauge
plex_fortress_guard_last_check $(date +%s)
EOF
}

# --- Main logic ---
run_guard() {
    mkdir -p "$(dirname "$LOG_FILE")"

    local health prev
    health=$(check_health)
    prev=$(read_state)

    case "$health" in
        HEALTHY)
            if [[ "$prev" != "HEALTHY" ]]; then
                success "plex.tv recovered ($prev -> HEALTHY) -- clearing blocks"
                unblock_all
            fi
            ;;
        DEGRADED)
            [[ "$prev" != "DEGRADED" ]] && warning "plex.tv degraded ($prev -> DEGRADED) -- blocking IPs"
            block_ips
            ;;
        UNREACHABLE)
            if [[ "$prev" == "DEGRADED" ]]; then
                log "plex.tv unreachable while degraded -- keeping blocks"
            elif [[ "$prev" != "UNREACHABLE" ]]; then
                log "plex.tv unreachable ($prev -> UNREACHABLE) -- Plex handles this natively"
            fi
            ;;
    esac

    write_state "$health"
    write_metrics "$health"
}

show_status() {
    local state blocked
    state=$(read_state)
    blocked=$(get_blocked_ips)
    local count
    count=$(echo "$blocked" | grep -c . 2>/dev/null || echo 0)

    echo "State: $state"
    echo "Blocked IPs: $count"
    [[ -n "$blocked" ]] && echo "$blocked" | sed 's/^/  /'
    echo "Health: $(check_health)"
}

# --- CLI ---
case "${1:-}" in
    --dry-run)    DRY_RUN=true; run_guard ;;
    --check-only) echo "$(check_health)" ;;
    --clear)      unblock_all; write_state "HEALTHY"; success "All rules cleared" ;;
    --status)     show_status ;;
    *)            run_guard ;;
esac
