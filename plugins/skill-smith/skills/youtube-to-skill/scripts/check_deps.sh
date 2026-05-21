#!/usr/bin/env bash
# check_deps.sh — report which youtube-to-skill dependencies are present.
#
# Exit codes:
#   0  all deps present
#   1  one or more missing (details printed to stdout as JSON)
#
# Output (stdout): a single JSON object describing each dep.

set -euo pipefail

MODEL_DIR="${HOME}/.cache/skill-smith/models"
MODEL_FILE="${MODEL_DIR}/ggml-base.en.bin"

check_bin() {
  local name="$1"
  local path
  if path=$(command -v "$name" 2>/dev/null); then
    printf '{"name":"%s","present":true,"path":"%s"}' "$name" "$path"
  else
    printf '{"name":"%s","present":false,"path":null}' "$name"
  fi
}

check_model() {
  if [[ -f "$MODEL_FILE" ]]; then
    local size
    size=$(stat -f%z "$MODEL_FILE" 2>/dev/null || stat -c%s "$MODEL_FILE" 2>/dev/null || echo 0)
    printf '{"name":"whisper-model","present":true,"path":"%s","bytes":%s}' "$MODEL_FILE" "$size"
  else
    printf '{"name":"whisper-model","present":false,"path":"%s","bytes":0}' "$MODEL_FILE"
  fi
}

YTDLP=$(check_bin yt-dlp)
FFMPEG=$(check_bin ffmpeg)
WHISPER=$(check_bin whisper-cli)
MODEL=$(check_model)

printf '{"deps":[%s,%s,%s,%s]}\n' "$YTDLP" "$FFMPEG" "$WHISPER" "$MODEL"

# Exit non-zero if anything is missing.
if [[ "$YTDLP" == *'"present":false'* ]] \
   || [[ "$FFMPEG" == *'"present":false'* ]] \
   || [[ "$WHISPER" == *'"present":false'* ]] \
   || [[ "$MODEL" == *'"present":false'* ]]; then
  exit 1
fi
