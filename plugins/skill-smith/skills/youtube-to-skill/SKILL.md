---
name: youtube-to-skill
description: Use when the user provides a YouTube URL and wants its content captured as a reusable Claude skill. Downloads the audio with yt-dlp, transcribes locally with whisper-cpp, drafts a SKILL.md via the skill-drafter subagent, and walks the user through a two-stage review (frontmatter, then body) before writing anything to disk.
version: 0.1.0
---

# YouTube to Skill

## Overview

Turn a YouTube URL into a polished `SKILL.md`. The pipeline is deliberately local-first: no API keys, no third-party transcript services, no leak of video content off-machine.

```
URL ─► yt-dlp (audio only) ─► whisper-cpp (transcript) ─► skill-drafter agent ─► two-stage review ─► SKILL.md on disk
```

## When to invoke

- User pastes a YouTube URL paired with "make a skill" / "save this as a skill" / "skillify this video".
- Routed here from `url-to-skill` after URL classification.

Do **not** invoke for: general YouTube summarization, transcript-only requests, downloading videos for offline viewing. Those are out of scope.

## Procedure

> **Important:** This skill writes files to disk only after the user accepts the draft (Stage B). On any failure, leave the tempdir intact and print its path.

### 0. Capture inputs

- `URL` — the YouTube URL.
- `MODE` — ask up front: **shared** (default, writes into `./plugins/skill-smith/skills/`) or **private** (`~/.claude/skills/`). Use `AskUserQuestion`.

### 1. Dependency check

Run `scripts/check_deps.sh`. For each missing dependency, print the `brew install` command and ask the user via `AskUserQuestion` whether to run it now. Do not auto-install without confirmation.

Dependencies:
- `yt-dlp` → `brew install yt-dlp`
- `ffmpeg` → `brew install ffmpeg`
- `whisper-cli` (from the `whisper-cpp` formula) → `brew install whisper-cpp`
- Whisper model at `~/.cache/skill-smith/models/ggml-base.en.bin` — if missing, download from Hugging Face (`https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin`, ~150 MB). Show the user the URL and size before fetching.

### 2. Audio download

```bash
TMPDIR=$(mktemp -d -t youtube-to-skill.XXXX)
bash plugins/skill-smith/skills/youtube-to-skill/scripts/download_audio.sh "$URL" "$TMPDIR"
```

Outputs:
- `$TMPDIR/audio.mp3` — audio track.
- `$TMPDIR/meta.json` — `yt-dlp --print-json` payload (title, channel, duration, video id, description).

Print the tempdir path so the user can poke at it if something goes wrong.

### 3. Transcribe

```bash
bash plugins/skill-smith/skills/youtube-to-skill/scripts/transcribe.sh "$TMPDIR/audio.mp3"
```

Output: `$TMPDIR/transcript.txt`.

For very long videos (>1 hour), warn the user that this may take several minutes.

### 4. Draft via subagent

Spawn the `skill-drafter` agent (run in background per project rules). Pass it:
- the absolute path to `$TMPDIR/transcript.txt`
- the absolute path to `$TMPDIR/meta.json`
- the chosen `MODE` (shared / private)
- the path to the skills directory it should scan when proposing slugs

Expect back, as a single structured response:
- `name` (kebab-case, ≤ 40 chars)
- `description` (one sentence, starts with "Use when…")
- `body_markdown` (Overview, When to invoke, Procedure, Examples)
- `related_skills` — list of `{slug, similarity_reason}` for skills it noticed thematic overlap with

Do not pass the transcript inline — only the path. The main thread must not load the full transcript into context.

### 5. Suggest append vs new

If `related_skills` is non-empty, show the user the top match and ask via `AskUserQuestion`:
- **Append to `<slug>`** — open that SKILL.md, ask the drafter to merge the new content as an additional section.
- **Create new** — use the proposed `name` as the slug.
- **Cancel** — bail without writing.

If `related_skills` is empty, default to creating new (no prompt).

### 6. Two-stage review

**Stage A — frontmatter:**

Print the proposed frontmatter in a fenced ```yaml``` block. Ask the user via `AskUserQuestion`:
- Accept
- Edit `name`
- Edit `description`
- Regenerate (re-run the drafter)

Loop until accepted.

**Stage B — body:**

Print the proposed body (markdown). Ask via `AskUserQuestion`:
- Accept
- Edit (user provides a free-text replacement or specific changes)
- Regenerate

Loop until accepted.

### 7. Write

Resolve the target path:
- shared + create new: `./plugins/skill-smith/skills/<slug>/SKILL.md`
- shared + append: existing `./plugins/skill-smith/skills/<slug>/SKILL.md`
- private + create new: `~/.claude/skills/<slug>/SKILL.md`
- private + append: existing `~/.claude/skills/<slug>/SKILL.md`

For "create new" — `mkdir -p` the directory and Write the file.
For "append" — Read the existing file, append the new section under the appropriate heading, Write back.

Print the final path.

### 8. Cleanup

On success: `rm -rf "$TMPDIR"`.
On any failure in steps 1–7: leave `$TMPDIR` in place and print its path so the user can inspect audio + transcript.

## Examples

**Happy path:**
```text
> /url-to-skill https://www.youtube.com/watch?v=ABC123
… (dispatcher routes to youtube-to-skill)
Mode? shared
Checking deps… all present.
Downloading audio to /tmp/youtube-to-skill.4f7c/ … done.
Transcribing (estimated 90s)… done.
Drafting skill via skill-drafter…
Found 1 related skill: `firecrawl-scrape` (both extract content from URLs). Append, new, or cancel? → new
Frontmatter:
  name: rag-with-pgvector
  description: Use when building retrieval-augmented generation on Postgres with pgvector…
Accept frontmatter? → accept
Body:
  ## Overview …
Accept body? → accept
Wrote ./plugins/skill-smith/skills/rag-with-pgvector/SKILL.md
Cleaned up /tmp/youtube-to-skill.4f7c/.
```

**Failure path:**
```text
yt-dlp failed: video unavailable.
Tempdir kept at /tmp/youtube-to-skill.9a2b/ for debugging.
```
