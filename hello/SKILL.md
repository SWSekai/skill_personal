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

### 3.4 Daily Brief Cross-Day Check

Per `team/references/daily-brief.md` §8, detect whether yesterday's brief has unresolved carry-over.

1. Compute today's `YYMMDD` from `date '+%y%m%d'`
2. Glob `.local/report/*_brief.md` and pick the file with the highest YYMMDD prefix
3. Branch:

| Condition | Behavior |
|---|---|
| No brief files exist | Skip (no output) |
| Latest brief's YYMMDD = today | Output inline: `本日 brief：N 完成 / M 進行中 / K 待辦` |
| Latest brief's YYMMDD < today | Show cross-day block (see below) |

4. Cross-day block template:

```
━━━ 跨日檢查 ━━━
昨日 brief：.local/report/YYMMDD_brief.md
  未處理交接：N 項（解析 §4 交接事項，非「無」即計數）
  modify_log 缺失：M 筆（§6 commit 記錄中標 ⚠️ 的 row 數）
今日 brief：尚未建立（將於今日首次觸發時新建）
━━━━━━━━━━━━━━
```

5. **No auto-rename, no auto-delete**: yesterday's brief stays under its original `YYMMDD_brief.md` filename (do NOT apply `CLOSED_` — that prefix is reserved for decision/whiteboard closure). "Cleanup" is achieved by natural YYMMDD partition when today's first trigger creates a fresh file.

6. If the user wants to carry yesterday's handoff forward → prompt subtly: `如需延續昨日交接到今日，執行 /team report --daily 手動合併`. Do not auto-merge.

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
