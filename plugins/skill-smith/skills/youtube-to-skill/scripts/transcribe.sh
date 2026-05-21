#!/usr/bin/env bash
# transcribe.sh AUDIO_FILE
#
# Transcribes AUDIO_FILE with whisper-cli using the ggml-base.en model.
# Writes the transcript next to the audio file as <basename>.txt and
# prints the transcript path to stdout.
#
# Requires whisper-cli (from `brew install whisper-cpp`) and the model at
# ~/.cache/skill-smith/models/ggml-base.en.bin.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 AUDIO_FILE" >&2
  exit 2
fi

AUDIO="$1"
if [[ ! -f "$AUDIO" ]]; then
  echo "audio file not found: $AUDIO" >&2
  exit 2
fi

MODEL="${HOME}/.cache/skill-smith/models/ggml-base.en.bin"
if [[ ! -f "$MODEL" ]]; then
  echo "whisper model missing: $MODEL" >&2
  echo "download with:" >&2
  echo "  mkdir -p \"$(dirname "$MODEL")\" && curl -L -o \"$MODEL\" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" >&2
  exit 1
fi

# whisper-cli expects 16kHz mono WAV. Convert via ffmpeg into the same dir.
WAV="${AUDIO%.*}.wav"
ffmpeg -y -loglevel error -i "$AUDIO" -ar 16000 -ac 1 -c:a pcm_s16le "$WAV"

# -otxt writes <of>.txt
OUT_BASE="${AUDIO%.*}"
whisper-cli \
  -m "$MODEL" \
  -f "$WAV" \
  -otxt \
  -of "$OUT_BASE" \
  --no-prints \
  > /dev/null

TRANSCRIPT="${OUT_BASE}.txt"
if [[ ! -f "$TRANSCRIPT" ]]; then
  echo "transcript not produced; whisper-cli may have failed" >&2
  exit 1
fi

echo "$TRANSCRIPT"
