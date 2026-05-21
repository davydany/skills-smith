# skill-smith

Forge new Claude Code skills from external content.

## Skills

- **`url-to-skill`** — umbrella dispatcher. Hand it a URL, it routes to the right specialized skill (YouTube today; webpage/PDF/etc. later).
- **`youtube-to-skill`** — YouTube URL → polished `SKILL.md`. Downloads audio with `yt-dlp`, transcribes locally with `whisper-cpp`, drafts via the `skill-drafter` subagent, and walks you through a two-stage review before writing anything.

## Install

From this repo (local dev):

```bash
claude plugin marketplace add /path/to/skill-smith
claude plugin install skill-smith
```

After installing, restart your Claude Code session so the skills register.

## Usage

```text
/url-to-skill https://www.youtube.com/watch?v=...
```

You'll be:
1. Prompted to install any missing system deps (`yt-dlp`, `ffmpeg`, `whisper-cpp`).
2. Shown the draft frontmatter for review/edit.
3. Shown the draft body for review/edit.
4. Asked whether to append to an existing skill (when one looks related) or create a new one.
5. Told the final write path.

## System dependencies

The `youtube-to-skill` pipeline uses (and will offer to install via Homebrew):

- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) — audio download
- [`ffmpeg`](https://ffmpeg.org/) — audio post-processing
- [`whisper-cpp`](https://github.com/ggml-org/whisper.cpp) — local transcription
- A whisper model file (`ggml-base.en.bin`, ~150 MB) auto-downloaded to `~/.cache/skill-smith/models/` on first run.

## Layout

```
plugins/skill-smith/
├─ .claude-plugin/plugin.json
├─ skills/
│  ├─ url-to-skill/SKILL.md
│  └─ youtube-to-skill/
│     ├─ SKILL.md
│     └─ scripts/
│        ├─ check_deps.sh
│        ├─ download_audio.sh
│        └─ transcribe.sh
└─ agents/
   └─ skill-drafter.md
```
