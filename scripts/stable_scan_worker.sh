#!/usr/bin/env bash
#
# Stable scan worker: scans ONE media file at multiple offsets and appends a single result line.
# Designed to be called by xargs (-P) for robust parallelism.
#
# Output format (pipe-delimited):
#   STATUS|hard=<n>|nal=<n>|<basename>|<fullpath>
#
set -euo pipefail

RESULTS_FILE="${1:?results file required}"
SLICE_SECONDS="${2:-15}"
TIMEOUT_SECONDS="${3:-25}"
FILE="${4:?file path required}"

# Important:
# - We intentionally IGNORE subtitle/data streams to avoid false positives like:
#   "Could not find codec parameters for stream X (Subtitle: hdmv_pgs_subtitle ...)"
# - "Invalid NAL" warnings alone are noisy, so we track them separately.
HARD_RE='(Invalid data found when processing input|error while decoding|decoding error|corrupt|moov atom not found|truncated|packet corrupt|non-existing PPS|missing picture|reference picture missing|cannot determine format|Header missing|concealing)'

if [[ ! -f "$FILE" ]]; then
  exit 0
fi

base="$(basename "$FILE")"

# Duration in seconds (int). If unknown, assume 3600s so offsets still spread out.
dur="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$FILE" 2>/dev/null | awk '{print int($1)}' || true)"
if [[ -z "${dur}" || "$dur" -le 0 ]]; then
  dur=3600
fi

# 11 points (0..91%) + EOF. Keep coverage high without relying on a full decode.
points=(0 0.09 0.18 0.27 0.36 0.45 0.55 0.64 0.73 0.82 0.91)

hard_total=0
nal_total=0

scan_segment() {
  local mode="$1" # offset|eof
  local val="$2"  # seconds offset or eof seconds

  local out hard nal
  if [[ "$mode" == "offset" ]]; then
    out="$(timeout "${TIMEOUT_SECONDS}" ffmpeg -hide_banner -nostats -v warning -sn -dn -ss "${val}" -i "$FILE" -t "${SLICE_SECONDS}" -f null - 2>&1 || true)"
  else
    out="$(timeout "${TIMEOUT_SECONDS}" ffmpeg -hide_banner -nostats -v warning -sn -dn -sseof "-${val}" -i "$FILE" -t "${SLICE_SECONDS}" -f null - 2>&1 || true)"
  fi

  hard="$(printf '%s' "$out" | grep -ciE "$HARD_RE" || true)"
  nal="$(printf '%s' "$out" | grep -ciE 'Invalid NAL' || true)"

  # sanitize and accumulate
  hard_total=$((hard_total + ${hard//[^0-9]/0}))
  nal_total=$((nal_total + ${nal//[^0-9]/0}))
}

for p in "${points[@]}"; do
  off="$(awk -v d="$dur" -v pct="$p" 'BEGIN{printf "%d", d*pct}')"
  scan_segment "offset" "$off"
done

# EOF sample: last SLICE_SECONDS seconds (still decode SLICE_SECONDS).
scan_segment "eof" "$SLICE_SECONDS"

status="OK"
# Conservative thresholds:
# - Any hard error => CORRUPT
# - Lots of Invalid NAL warnings => likely corruption/freezing risk
if [[ "$hard_total" -ge 1 || "$nal_total" -ge 500 ]]; then
  status="CORRUPT"
elif [[ "$nal_total" -ge 120 ]]; then
  status="SUSPICIOUS"
fi

#
# "Truly bad" confirmation:
# If we think it's CORRUPT, run a stricter decode pass that only logs real decode errors.
# This avoids false positives from noisy warnings/subtitle probe issues.
#
confirm_truly_bad() {
  local mid
  mid=$((dur / 2))

  # If ffmpeg exits non-zero with -xerror, or prints anything at loglevel=error, we treat it as truly bad.
  local out rc
  for mode in start middle end; do
    if [[ "$mode" == "start" ]]; then
      out="$(timeout "${TIMEOUT_SECONDS}" ffmpeg -hide_banner -nostats -nostdin -loglevel error -xerror -sn -dn -ss 0 -i "$FILE" -t "${SLICE_SECONDS}" -f null - 2>&1)"
      rc=$?
    elif [[ "$mode" == "middle" ]]; then
      out="$(timeout "${TIMEOUT_SECONDS}" ffmpeg -hide_banner -nostats -nostdin -loglevel error -xerror -sn -dn -ss "${mid}" -i "$FILE" -t "${SLICE_SECONDS}" -f null - 2>&1)"
      rc=$?
    else
      out="$(timeout "${TIMEOUT_SECONDS}" ffmpeg -hide_banner -nostats -nostdin -loglevel error -xerror -sn -dn -sseof "-${SLICE_SECONDS}" -i "$FILE" -t "${SLICE_SECONDS}" -f null - 2>&1)"
      rc=$?
    fi

    # timeout returns 124; treat that as inconclusive (don't auto-downgrade)
    if [[ "$rc" -eq 124 ]]; then
      return 0
    fi

    if [[ "$rc" -ne 0 ]]; then
      return 0
    fi
    if [[ -n "$out" ]]; then
      return 0
    fi
  done

  # No errors at all in strict mode => not truly bad
  return 1
}

if [[ "$status" == "CORRUPT" ]]; then
  if ! confirm_truly_bad; then
    # Downgrade: we didn't see real decode errors in strict mode
    if [[ "$nal_total" -ge 120 ]]; then
      status="SUSPICIOUS"
    else
      status="OK"
    fi
  fi
fi

line="${status}|hard=${hard_total}|nal=${nal_total}|${base}|${FILE}"

# Append atomically with lock (prevents interleaving under xargs -P)
{
  flock -w 30 200 || exit 1
  printf '%s\n' "$line" >> "$RESULTS_FILE"
} 200>"${RESULTS_FILE}.lock"


