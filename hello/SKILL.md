---
name: hello
description: "Conversation initialization entry point — automatically pulls project + Skill updates, restores context, and displays status overview. Replaces the legacy auto-sync-on-conversation-start mechanism."
model: sonnet
effort: low
argument-hint: ""
allowed-tools: Read, Glob, Grep, Bash(git *), Bash(ls *), Bash(date *), Bash(docker *)
---

# /hello — Conversation Initialization

Call at the start of every new conversation to complete in one stop: pull updates → sync Skills → restore context → status overview.

**Replaces the legacy "auto-sync on conversation start" mechanism in CLAUDE.md Rule 12** — now triggered explicitly by the user for better control.

---

## Step 1: Pull Project Updates

```bash
# Project itself
git fetch origin
git status
```

- If upstream has updates → show how many commits `origin/HEAD` is ahead; **do not auto-merge** (avoids conflicts)
- Notify user: "Remote has N new commits; run `git pull` when needed"
- If already up to date → show "Project is up to date"

---

## Step 2: Sync Skill Updates (merges legacy `/skill sync` flow one)

> This step integrates the "Flow One: Remote Sync" logic from the legacy `/skill sync`.
> `/skill sync` still retains "Flow Two: Rule Evaluation & Three-Way Linkage" for use when writing to Memory.

### 2.1 Check flowback.pull Setting

Read `sekai_workflow.flowback.pull` from `.claude/settings.local.json`:

| State | Behavior |
|---|---|
| `true` (default) | Proceed to 2.2 |
| `false` | Skip remote pull, only do local sync (2.3) |

### 2.2 Execute sp-sync.sh (Remote Sync)

```bash
bash Sekai_workflow/_bootstrap/sp-sync.sh
```

Script behavior (same as legacy `/skill sync` flow one):
1. `git fetch origin` to get remote updates
2. Compare local and remote commits
3. If updates exist → `git pull --rebase origin main`
4. Compare each skill's SKILL.md / README.md between `Sekai_workflow/` and `.claude/skills/`
5. Automatically copy new or differing skills to `.claude/skills/`
6. Output Added / Updated / No change summary

**Cases the script cannot handle**:
- Pull conflicts → abort and notify user to resolve manually
- New skills → script only copies files; CLAUDE.md's available Skills list must be updated manually

### 2.3 Supplementary Sync (items not covered by the script)

After the script finishes, Claude performs additional checks:
- Whether `sekai-workflow/manifest.json` contains new skills missing from `.claude/skills/` → copy them over
- Whether `.claude/skills/README.md` needs updating → prompt the user

Output sync summary:

```
Skill sync:
  Updated: commit-push, team-office (2)
  Added: hello (1)
  Skipped: build (local is newer)
  No change: ask, context-guard, setup, memory-portable
```

---

## Step 3: Restore Context

### 3.1 Read Latest context_summary

Scan `.local/context_summary/*.md` (excluding `current_topic.md`), sort by filename date, read the latest 1~2 files:

- If summaries exist → display a condensed "last work summary" (3~5 lines)
- If none → skip

### 3.2 Read current_topic

Read `.local/context_summary/current_topic.md`:

- If exists → display "Current topic: <topic>"
- If not → skip

### 3.3 Read TODOs

Read `.local/collab/TODO.md`:

- If Pending / In Progress items exist → summarize the top 3~5
- If none → skip

---

## Step 4: Status Overview

Output a condensed project status (readable within one screen):

```
━━━ /hello ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: <PROJECT_NAME>
Branch: <branch> (↑N ↓M vs origin)
Last commit: <hash> <message> (<time ago>)

Skill sync: ✓ Synced (N updates)
Context: <last topic>
TODO: N pending

Uncommitted changes: N files
Unpushed commits: N

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 5: Environment Health Check (optional, only runs if Docker is present)

If the project has `docker-compose.yml`:

```bash
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}" 2>/dev/null
```

- If services exist → summarize the count of running / stopped / unhealthy
- If no Docker / Docker not running → skip (no error)

---

## Relationship with Other Skills

| Skill | Relationship |
|---|---|
| `/skill sync` | `/hello` Step 2 reuses sync logic; sync can still be invoked standalone for full sync (including conflict resolution) |
| `/context-guard` | `/hello` Step 3 reads summaries produced by context-guard |
| `/team todo` | `/hello` Step 3 reads TODO status |
| `/skill pack` | Mutually exclusive: after pack the environment is cleared, so /hello cannot run |
| `/team handoff` | Complementary: the AI bundle produced by handoff can be manually loaded by the AI after `/hello` in a new conversation |

---

Arguments: $ARGUMENTS
