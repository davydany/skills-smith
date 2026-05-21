# skill-maker

A Claude Code plugin marketplace for **forging new skills from the wild** — point it at a URL, a YouTube video, or a transcript, and it turns the content into a reviewable `SKILL.md` you can drop into any Claude Code workflow. Also ships a small library of opinionated behavioral skills built using its own pipeline.

## Install the marketplace

```bash
# Add this repo as a Claude Code marketplace
claude plugin marketplace add /path/to/skill-maker

# Install the plugin (currently one: skill-smith)
claude plugin install skill-smith
```

Restart your Claude Code session so the skills register.

> For remote install, swap the local path for the git URL once published: `claude plugin marketplace add https://github.com/davydany/skill-maker`.

## Skills

| Name | Description | Usage notes |
|---|---|---|
| `url-to-skill` | Umbrella dispatcher. Hand it any URL — it detects the kind (YouTube, webpage, PDF, etc.) and routes to the right specialized skill. | `/url-to-skill <url>` — start here when you don't want to think about which pipeline applies. YouTube is wired up today; other kinds land as siblings. |
| `youtube-to-skill` | YouTube URL → polished `SKILL.md`. Downloads audio with `yt-dlp`, transcribes locally with `whisper-cpp`, drafts via the `skill-drafter` subagent, and walks you through a two-stage review (frontmatter, then body) before writing anything. | Requires `yt-dlp`, `ffmpeg`, `whisper-cpp` (the skill offers to install via Homebrew). A ~150 MB whisper model is cached to `~/.cache/skill-smith/models/` on first run. Fully local — no transcription API calls. |
| `counter-innovators-bias` | Behavioral skill. Detects when a founder/builder is over-building, endlessly polishing, or avoiding customer contact, and redirects them toward customer-learning experiments. | Auto-activates when collaborating on startup/product work and the anti-pattern shows up. No arguments — Claude invokes it from context. Built using the `youtube-to-skill` pipeline as a dogfooding example. |

## Layout

```
skill-maker/
├─ .claude-plugin/
│  └─ marketplace.json         # marketplace manifest
└─ plugins/
   └─ skill-smith/             # the only plugin (today)
      ├─ .claude-plugin/plugin.json
      ├─ skills/
      │  ├─ url-to-skill/
      │  ├─ youtube-to-skill/
      │  └─ counter-innovators-bias/
      └─ agents/
         └─ skill-drafter.md   # subagent that writes the draft
```

Each plugin is self-contained — copy `plugins/skill-smith/` into another repo and it works standalone.
