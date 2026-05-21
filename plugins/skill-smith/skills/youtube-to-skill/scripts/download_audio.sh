#!/usr/bin/env bash
# download_audio.sh URL TMPDIR
#
# Downloads the audio track of a YouTube URL into TMPDIR/audio.mp3 and
# writes metadata to TMPDIR/meta.json.
#
# Requires yt-dlp + ffmpeg on PATH.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 URL TMPDIR" >&2
  exit 2
fi

URL="$1"
TMPDIR="$2"

if [[ ! -d "$TMPDIR" ]]; then
  echo "tempdir does not exist: $TMPDIR" >&2
  exit 2
fi

# --print-json prints metadata to stdout; we tee it for the caller.
# -x extracts audio; --audio-format mp3 normalizes via ffmpeg.
# -o sets the output template.
yt-dlp \
  -x --audio-format mp3 \
  --no-playlist \
  -o "${TMPDIR}/audio.%(ext)s" \
  --print-json \
  --no-progress \
  "$URL" > "${TMPDIR}/meta.json"

if [[ ! -f "${TMPDIR}/audio.mp3" ]]; then
  echo "audio.mp3 not produced; check ${TMPDIR}/meta.json and yt-dlp output" >&2
  exit 1
fi

echo "${TMPDIR}/audio.mp3"
