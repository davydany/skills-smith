---
name: url-to-skill
description: Use when the user provides a URL and asks to turn it into a Claude skill — phrases like "make a skill from this link", "save this video as a skill", "turn this page into a skill", or any time a URL is paired with "skill". Detects the URL kind and dispatches to the right specialized skill.
version: 0.1.0
---

# URL to Skill (dispatcher)

## Overview

This skill is the front door for "take this URL, make it a Claude skill." It does not generate the skill itself — it classifies the URL and hands off to the specialized handler.

## When to invoke

Whenever the user:
- Pastes a URL with a request to "make a skill from this" / "save this as a skill" / "skillify this link".
- Says they want the *content* behind a link captured as a reusable skill (not the link itself stored).

Do **not** invoke this skill for general web fetching, scraping, or summarizing — use the appropriate `firecrawl-*` or `WebFetch` tool instead.

## Procedure

1. **Read the URL** from the user's message (or `$ARGUMENTS` if invoked as `/url-to-skill <url>`).
2. **Classify** by hostname:
   | Pattern | Handler |
   |---|---|
   | `youtube.com` / `youtu.be` / `m.youtube.com` | `youtube-to-skill` |
   | anything else | not-yet-supported (see step 4) |
3. **Dispatch** by invoking the matching skill with the URL. For YouTube: tell the user "Routing to `youtube-to-skill`" and then follow the procedure in `plugins/skill-smith/skills/youtube-to-skill/SKILL.md`.
4. **Unsupported handler** — say plainly:
   > I can't turn that URL into a skill yet. Supported sources today: YouTube. Planned: arbitrary webpages, PDFs, arXiv. Want me to fall back to fetching the page and drafting a skill manually?
   Then wait for the user to choose. Do not silently fetch.

## Adding a new handler

When a new handler skill (e.g. `webpage-to-skill`) lands in `plugins/skill-smith/skills/`, add a row to the dispatch table above. Each handler is a sibling skill — this one stays lightweight and routing-only.
