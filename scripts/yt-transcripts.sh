#!/usr/bin/env bash
# Pull YouTube transcripts in bulk, then hand them to Claude Code for review.
#
# Usage:
#   ./yt-transcripts.sh <output_dir> <video_url_or_id> [<video_url_or_id>...]
#   ./yt-transcripts.sh <output_dir> -f urls.txt
#
# Requires:
#   - yt-dlp  (brew install yt-dlp)
#   - jq      (brew install jq)         optional, for clean metadata
#
# Fallback if YouTube has no auto-captions:
#   - whisper.cpp or openai-whisper for local transcription from audio

set -euo pipefail

OUT="${1:-}"
shift || true

if [[ -z "${OUT}" || $# -eq 0 ]]; then
  echo "usage: $0 <output_dir> <url_or_id> [more_urls...] | -f urls.txt"
  exit 2
fi

mkdir -p "${OUT}"
cd "${OUT}"

# Expand -f file.txt into a list of URLs
URLS=()
if [[ "$1" == "-f" ]]; then
  shift
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    URLS+=("$line")
  done < "$1"
else
  URLS=("$@")
fi

for U in "${URLS[@]}"; do
  # Accept bare 11-char IDs or full URLs
  if [[ "$U" =~ ^[A-Za-z0-9_-]{11}$ ]]; then
    URL="https://www.youtube.com/watch?v=${U}"
  else
    URL="$U"
  fi

  echo "==> ${URL}"

  # Try auto-generated English subtitles first
  yt-dlp \
    --skip-download \
    --write-auto-sub \
    --sub-lang en \
    --sub-format "srt/vtt/best" \
    --convert-subs srt \
    --output "%(id)s_%(title).80s.%(ext)s" \
    "${URL}" || {
      echo "    (no auto-subs; consider whisper fallback)"
    }
done

# Clean up: strip SRT timestamps to flat text for easier review
for srt in *.en.srt; do
  [[ -f "$srt" ]] || continue
  txt="${srt%.en.srt}.txt"
  # Remove sequence numbers, timestamp lines, and blank lines
  awk '
    /^[0-9]+$/ { next }
    /^[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}/ { next }
    /^$/ { next }
    { print }
  ' "$srt" | sed 's/<[^>]*>//g' > "$txt"
  echo "    -> ${txt}"
done

echo ""
echo "Done. Plain-text transcripts in ${OUT}/*.txt"
echo "Pipe a transcript to Claude Code with: cat *.txt | pbcopy  (then paste into the prompt)"
echo "Or use: claude < transcript.txt   for direct CLI input"
