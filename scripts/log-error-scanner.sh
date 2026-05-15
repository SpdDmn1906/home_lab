#!/bin/bash
# Scans docker container logs for error patterns and exports top 10
# as Prometheus metrics via node_exporter textfile collector.
# Also writes per-pattern JSON detail files served at :9800.

set -euo pipefail

METRICS_FILE="/var/lib/node_exporter/textfile_collector/container_log_errors.prom"
JSON_DIR="/opt/homelab/error-logs"
LOOKBACK="6h"
CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null | sort)
TMPFILE=$(mktemp)
RAWFILE=$(mktemp)
trap "rm -f $TMPFILE $RAWFILE" EXIT

mkdir -p "$JSON_DIR"

for cname in $CONTAINERS; do
    lines=$(docker logs "$cname" --since "$LOOKBACK" --timestamps 2>&1 \
        | grep -iE '\b(error|fatal|exception|fail|critical|warn)\b' \
        | grep -viE 'isWarning|"severity"' \
        || true)

    [[ -z "$lines" ]] && continue

    while IFS= read -r line; do
        ts=$(echo "$line" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)
        epoch=0
        [[ -n "$ts" ]] && epoch=$(date -u -d "$ts" +%s 2>/dev/null || echo 0)

        normalized=$(echo "$line" \
            | sed -E 's/^[0-9T:.,Z +-]+//' \
            | sed -E 's/[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}[T ]?[0-9:.,]+[Z ]?//g' \
            | sed -E 's/\b[0-9a-f]{8,}\b/ID/g' \
            | sed -E 's/[0-9]+(\.[0-9]+)?/N/g' \
            | sed -E 's/\s+/ /g' \
            | sed -E 's/^ +| +$//g' \
            | cut -c1-120)

        [[ -z "$normalized" ]] && continue
        # tab-separated: epoch, container, normalized_pattern, raw_line
        printf '%s\t%s\t%s\t%s\n' "$epoch" "$cname" "$normalized" "$line" >> "$TMPFILE"
    done <<< "$lines"
done

# aggregate counts + max timestamp
awk -F'\t' '{
    key = $2 "\t" $3
    counts[key]++
    if ($1+0 > last_seen[key]+0) last_seen[key] = $1
}
END {
    for (key in counts)
        print counts[key] "\t" last_seen[key] "\t" key
}' "$TMPFILE" | sort -t$'\t' -k1 -rn | head -10 > "${TMPFILE}.top"

# clean old json files
rm -f "$JSON_DIR"/*.json

now=$(date +%s)

{
    echo "# HELP container_log_errors Top error patterns from container logs (last ${LOOKBACK})"
    echo "# TYPE container_log_errors gauge"

    while IFS=$'\t' read -r count epoch cname pattern; do
        # stable hash for this (container, pattern) pair
        hash=$(echo -n "${cname}|${pattern}" | md5sum | cut -c1-12)

        safe_pattern=$(echo "$pattern" | sed 's/\\/\\\\/g; s/"/\\"/g')
        diff=$(( now - epoch ))
        if   (( diff < 60 ));    then ago="<1 min ago"
        elif (( diff < 3600 ));  then ago="$(( diff / 60 )) min ago"
        elif (( diff < 86400 )); then ago="$(( diff / 3600 )) hr ago"
        else                          ago="$(( diff / 86400 )) days ago"
        fi
        echo "container_log_errors{container=\"${cname}\",pattern=\"${safe_pattern}\",last_seen=\"${ago}\",hash=\"${hash}\"} ${count}"

        # build JSON detail file with recent raw log lines for this pattern
        # grab last 25 raw lines matching this container+pattern
        raw_lines=$(awk -F'\t' -v c="$cname" -v p="$pattern" '$2==c && $3==p {print $4}' "$TMPFILE" | tail -25)
        first_ts=$(awk -F'\t' -v c="$cname" -v p="$pattern" '$2==c && $3==p {print $1}' "$TMPFILE" | sort -n | head -1)
        first_time=$(date -u -d "@$first_ts" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")
        last_time=$(date -u -d "@$epoch" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")

        # write JSON using python for safe escaping
        python3 -c "
import json, sys
lines = sys.stdin.read().strip().split('\n')
lines = [l for l in lines if l]
obj = {
    'container': '$cname',
    'pattern': '''$pattern''',
    'count': $count,
    'first_seen': '$first_time',
    'last_seen': '$last_time',
    'lookback': '$LOOKBACK',
    'recent_logs': lines
}
print(json.dumps(obj, indent=2))
" <<< "$raw_lines" > "$JSON_DIR/${hash}.json"

    done < "${TMPFILE}.top"
} > "${METRICS_FILE}.tmp"

mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
