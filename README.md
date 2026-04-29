# Sekai-workflow

**A portable, opinionated workflow pack for [Claude Code](https://claude.com/claude-code) — drop it into any project and your AI assistant instantly knows how to plan, implement, commit, and hand off work.**

**English** · [繁體中文](./README.zh-TW.md) · [日本語](./README.ja.md)

> ⚠️ **Renamed something?** The single source of truth for global rename history is [`_bootstrap/RENAME_HISTORY.md`](./_bootstrap/RENAME_HISTORY.md). When you spot an old name, run a global `grep` and clean it up per the checklist there. Per-skill `Cross-Skill References` sections in each `SKILL.md` / `README.md` only list that skill's own renames.

---

## What is this?

Sekai-workflow is a curated set of Claude Code **Skills** (slash commands) and hooks that encode a full engineering workflow — planning, implementation, testing, quality review, commit/push, and cross-session context handoff.

It is **project-agnostic by design**: no service names, no hardcoded paths, no business logic. One-command install gives any repository the same consistent AI behaviour.

> Think of it as `eslint + prettier + conventional-commits + a style guide`, but for the way Claude Code collaborates with you.

## Why use it?

Working with an AI coding assistant across many projects surfaces the same pain points:

- 🔁 **Re-explaining the same rules** every new conversation ("use Conventional Commits", "don't edit auto-generated files", "write the change log in this format"…)
- 🧩 **Context loss** between sessions — long chats hit the compaction wall and the assistant forgets half the decisions you made.
- 🏗️ **Ad-hoc workflows** — each developer drives Claude slightly differently, so outputs are inconsistent across a team.
- 🧹 **Post-edit cleanup** — quality checks, redundancy scans, change logs, container restart evaluation get skipped under time pressure.

Sekai-workflow solves this by shipping a **reusable set of slash commands** and guard hooks that run the repetitive parts for you, automatically.

## Features at a glance

Nine command entry-points (all invoked via `/command`):

| Command | Purpose | Typical trigger |
|---|---|---|
| `/hello` | Conversation bootstrap — pull updates, restore prior context, show status | Start of each session |
| `/build <all\|plan\|do\|test\|check\|review\|deploy>` | End-to-end dev flow: analyze → design → implement → test → quality → review → deploy | You're about to build something |
| `/commit-push [msg]` | Main commit entry — quality check → change log → README sync → commit → push → deploy eval → context cleanup | After a coherent chunk of work |
| `/team <todo\|board\|decide\|note\|handoff\|report\|journal\|follow-up>` | Human-AI collaboration: todos, whiteboards, Markdown decision tables, tech notes, handoff docs, project journal | Planning / decision moments |
| `/ask <info\|trace>` | Ask questions about the codebase / trace a field end-to-end through the stack | "How does X flow?" questions |
| `/skm <new\|sync\|pack\|update>` | Manage the Skill environment itself — create, sync with upstream, package for handoff. Renamed from `/skill` on 2026-04-24 to avoid conflict with built-in `/skills` dialog | Skill maintenance |
| `/clean [check\|force]` | Context window hygiene — summarize, archive, `/clear`, auto-restore | When the chat gets long |
| `/memo` | Carry feedback / preference memory across projects | Onboarding a new repo |
| `/dispatch <task>` | Route a task to the right model tier (Opus / Sonnet / Haiku) via a real Agent call | Model-heterogeneous work |

## Quick start

### Prerequisites

- [Claude Code CLI](https://claude.com/claude-code) installed and authenticated
- Git
- A project directory (new or existing) — or just an empty folder

### Install (30 seconds)

```bash
# 1. Clone sekai-workflow next to (or anywhere outside) your project
git clone https://github.com/SWSekai/sekai-workflow.git

# 2. From your project's root, run the bootstrap script
#    Windows:
C:\path\to\sekai-workflow\_bootstrap\sp-init.bat

#    macOS / Linux / WSL (coming soon — use sp-init.bat via Wine or see docs/QUICKSTART.md)
```

The bootstrap:

1. Creates `.claude/skills/` and copies all skills into your project
2. Creates a local `Sekai_workflow/` (auto-renamed to `.sekai-workflow/` after first run) that tracks this upstream repo for updates
3. Generates a `CLAUDE.md` ruleset tuned for Claude Code
4. Installs a `pre-commit` hook that blocks Skill files from being committed to your project by mistake
5. Ensures `.gitignore` excludes everything AI-related

All of the above lives outside your project's version control — **your repo only commits your code.**

### Verify

```bash
# Check that every protective layer is in place
C:\path\to\sekai-workflow\_bootstrap\sp-verify.bat C:\your\project
```

## Your first workflow

Once installed, open Claude Code inside your project and try:

```
/hello          # Restore context + check for upstream updates
/build plan     # Describe a feature → get a structured plan (Opus)
/build do       # Claude implements step-by-step, checks boxes as it goes
/commit-push    # Quality scan → changelog → README touch-ups → commit → push
/clean          # When the chat is long: summarize, archive, /clear
```

That's the full inner loop. Every command is documented with its own `SKILL.md` and `README.md` inside the corresponding folder — Claude reads these automatically, so you never have to memorize them.

## How it works

Three layers, one source of truth:

```
┌──────────────────────────────────────────────────────────┐
│  github.com/SWSekai/sekai-workflow   (this repo)         │  ← upstream template
└─────────────────────────┬────────────────────────────────┘
                          │ clone / /skm sync
                          ▼
┌──────────────────────────────────────────────────────────┐
│  <your-project>/.sekai-workflow/   (local template copy) │  ← git-ignored
└─────────────────────────┬────────────────────────────────┘
                          │ sp-init.bat / /skm sync
                          ▼
┌──────────────────────────────────────────────────────────┐
│  <your-project>/.claude/skills/    (active skills)       │  ← git-ignored
└──────────────────────────────────────────────────────────┘
```

- **Upstream updates** — someone improves a Skill → `/hello` or `/skm sync` pulls it into your project.
- **Downstream flowback** — you improve a Skill locally → if the change is generic, `/skm sync` offers to push it back upstream (opt-in; defaults to local-only).
- **Project-specific tweaks** stay in `.claude/skills/` and are never pushed back.

### Version control boundaries

| Path | Who owns it | In your project's git? |
|---|---|:---:|
| Your source code | Your project | ✅ |
| `.claude/skills/` | Local only | ❌ |
| `.sekai-workflow/` | This upstream repo | ❌ |
| `CLAUDE.md` | Local only | ❌ |
| `.local/` (logs, summaries, reports) | Local working notes | ❌ |

The bootstrap ensures your `.gitignore` enforces this automatically. **Never `git add -f` any of the AI files** — the pre-commit hook will stop you.

## Customization

Every Skill is designed to be edited. Open any `.claude/skills/<skill>/SKILL.md` and adjust:

- **Paths** — where change logs, summaries, decision tables go
- **Services** — Docker container names, compose file paths, deploy commands
- **Language** — commit-message language, UI text preferences
- **Flow** — add/remove steps, change triggers

Your edits stay local. If you think a change is generic enough to benefit everyone, flag it and `/skm sync` can contribute it upstream.

## Documentation

- [QUICKSTART](./docs/QUICKSTART.md) — a walkthrough with screenshots and common scenarios
- [File output reference](./docs/file-output-reference.md) — where each command writes its artefacts
- [`manifest.json`](./manifest.json) — machine-readable index of every skill, its model tier, and allowed tools
- Per-skill docs live under each skill folder (`build/README.md`, `team/README.md`, …)

## Model tiering

Skills are assigned to model tiers per workload:

- **Opus** — planning, quality review, architecture decisions, deep analysis
- **Sonnet** — multi-step execution, file editing, standard dev tasks
- **Haiku** — structured text generation (change logs, status checks, templates)

`/dispatch` provides real tier-switching via the Agent tool when a single task needs a specific model. See [`references/model-routing.md`](./references/model-routing.md) for the full mapping.

## Contributing

Issues and PRs welcome. The main repo lives at [github.com/SWSekai/sekai-workflow](https://github.com/SWSekai/sekai-workflow).

When contributing a Skill change, run `/skm sync` first so your diff is against latest upstream.

Translations of this README are appreciated — add `README.<lang>.md` next to this file and update the language switcher at the top of each README.

## License

See [LICENSE](./LICENSE) if present; otherwise treat as all-rights-reserved pending upstream clarification.

---

> **Looking for the detailed operator manual?** That used to live in this README and has moved to [docs/QUICKSTART.md](./docs/QUICKSTART.md) and the per-skill `README.md` files, so this page stays friendly for first-time visitors.
