---
name: hello
description: "Conversation initialization entry point — pull updates → sync Skills → reconstruct work state (scan decision/whiteboard/context-summary → consolidate unfinished items into TODO) → status overview."
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
git fetch origin
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git log HEAD..origin/$BRANCH --oneline 2>/dev/null | head -10
```

- If upstream has updates:
  1. Show new commit count and list (max 10 entries)
  2. Call AskUserQuestion: **"專案遠端有 N 個新 commit，是否套用？"**
     - `立即套用（git pull --rebase）` ← (Recommended)
     - `稍後手動執行（僅記錄）`
  3. If apply → `git pull --rebase origin <branch>`
  4. If skip → note "Project updates: N commits pending" in Step 4 status overview
- If already up to date → proceed to Step 2

---

## Step 2: Sync Skill Updates (merges legacy `/skm sync` flow one)

> This step integrates the "Flow One: Remote Sync" logic from the legacy `/skm sync`.
> `/skm sync` still retains "Flow Two: Rule Evaluation & Three-Way Linkage" for use when writing to Memory.

### 2.1 Check flowback.pull Setting

Read `sekai_workflow.flowback.pull` from `.claude/settings.local.json`:

| State | Behavior |
|---|---|
| `true` (default) | Proceed to 2.2 |
| `false` | Skip remote pull, only do local sync (2.3) |

### 2.2 Preview and Apply Skill Library Updates

Before running the sync script, preview what's available:

```bash
cd Sekai_workflow && git fetch origin
git log HEAD..origin/main --oneline 2>/dev/null | head -10
```

- If Skill library has updates:
  1. Show new commit list (max 10 entries) as a preview
  2. Call AskUserQuestion: **"全域 Skill 庫有 N 個新版本可套用，是否立即同步？"**
     - `套用（執行 sp-sync.sh）` ← (Recommended)
     - `跳過（保留目前版本）`
  3. If apply → `bash Sekai_workflow/_bootstrap/sp-sync.sh`
  4. If skip → note "Skill library: N commits pending" in Step 4 status overview
- If already up to date → proceed to Step 2.3

**sp-sync.sh behavior** (when executed):
1. `git pull --rebase origin main` in Sekai_workflow/
2. Compare each skill's SKILL.md / README.md between `Sekai_workflow/` and `.claude/skills/`
3. Automatically copy new or differing skills to `.claude/skills/`
4. Output Added / Updated / No change summary

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

## Step 3: Work State Reconstruction

**Core goal**: reconstruct unfinished work from all persistent artifacts of previous sessions and consolidate into TODO.md so the user can immediately continue from where they left off — especially after a weekend or multi-day gap.

### 3.1 Load Context Window

Scan `.local/context_summary/*.md` (excluding `current_topic.md`), sort by filename date, read the latest 1–2 files. Also read `.local/context_summary/current_topic.md` if it exists.

From these summaries, extract **candidate unfinished items**: tasks marked as "in progress", "next steps", "TODO", or "未完成" in the summary text. Build an internal candidate list; do **not** output yet.

If no summaries exist → candidate list starts empty; continue to 3.2.

### 3.2 Scan Open Decision & Whiteboard Files

Glob the following, **excluding** files prefixed with `CLOSED_`:
- `.local/docs/decision/*.md`
- `.local/docs/whiteboard/*.md`

For each open file:
- Extract all unchecked `[ ]` Markdown task items
- Label each with source file name and section reference (e.g., `§1.2`)

Add labeled items to the candidate list. Do **not** output yet.

### 3.3 Deduplicate Against TODO.md

Read `.local/collab/TODO.md`:
- If file does not exist → create it with basic scaffold (`## Pending\n\n## In Progress\n\n## Completed`) per CLAUDE.md Rule 17.1.8
- For each candidate: fuzzy-match against existing **Pending** and **In Progress** entries
- Mark as **SKIP** if already present; mark as **ADD** if new

### 3.4 Consolidate into TODO.md

For each item marked **ADD**, append to the `## Pending` section:
```
- [ ] <item> *(來源: <source-file> <§ref>)*
```
Use the Edit tool; never overwrite existing content.

If zero items added → note internally "無新項目" (TODO is already up to date); no error output.

### 3.5 Daily Report Cross-Day Check

Per `team/references/daily-report.md` §8, detect whether yesterday's daily report has unresolved carry-over.

1. Compute today's `YYMMDD` from `date '+%y%m%d'`
2. Glob `.local/report/*_daily_report.md` and pick the file with the highest YYMMDD prefix
3. Branch:

| Condition | Behavior |
|---|---|
| No daily report files exist | Skip (no output) |
| Latest daily report's YYMMDD = today | Output inline: `本日報告：N 完成 / M 進行中 / K 待辦` |
| Latest daily report's YYMMDD < today | Show cross-day block (see below) |

4. Cross-day block template:

```
━━━ 跨日檢查 ━━━
昨日報告：.local/report/YYMMDD_daily_report.md
  未處理交接：N 項（解析 §4 交接事項，非「無」即計數）
  modify_log 缺失：M 筆（§6 commit 記錄中標 ⚠️ 的 row 數）
今日報告：尚未建立（將於今日首次觸發時新建）
━━━━━━━━━━━━━━
```

5. **No auto-rename, no auto-delete**: yesterday's daily report stays under its original `YYMMDD_daily_report.md` filename (do NOT apply `CLOSED_`). Cleanup is achieved by natural YYMMDD partition when today's first trigger creates a fresh file.

6. If the user wants to carry yesterday's handoff forward → prompt subtly: `如需延續昨日交接到今日，執行 /team report --daily 手動合併`. Do not auto-merge.

### 3.6 Display Work Reconstruction Summary

Output condensed reconstruction block after all writes are complete:

```
━━━ 工作狀態重建 ━━━
掃描來源：context_summary（N 檔）/ 開放決策表（N 個）/ 開放白板（N 個）
新整合至 TODO：N 項 ┃ 已略過重複：N 項
━━━━━━━━━━━━━━━━━━━
今日可處理：
  🔄 In Progress: <item>
  ⬜ Pending: <item>
  ⬜ Pending: <item>
  （+ N 項，執行 /team todo 查看全部）
```

If nothing was found or consolidated → output: `━━━ 工作狀態重建：TODO 已是最新，無新項目 ━━━`

---

## Step 4: Status Overview

Output a condensed project status (readable within one screen):

```
━━━ /hello ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: <PROJECT_NAME>
Branch: <branch> (↑N ↓M vs origin)
Last commit: <hash> <message> (<time ago>)

Updates: Project ✓ up to date | ⚠ N commits pending  /  Skill sync ✓ | ⚠ N commits pending
Context: <last topic>
TODO: In Progress N / Pending N

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
| `/skm sync` | `/hello` Step 2 reuses sync logic; sync can still be invoked standalone for full sync (including conflict resolution) |
| `/clean` | `/hello` Step 3 reads summaries produced by `/clean` (which inherited context-guard's responsibilities) |
| `/team todo` | `/hello` Step 3 reads TODO status |
| `/skm pack` | Mutually exclusive: after pack the environment is cleared, so /hello cannot run |
| `/team handoff` | Complementary: the AI bundle produced by handoff can be manually loaded by the AI after `/hello` in a new conversation |

---

## Cross-Skill References

| Direction | Target | Trigger / Purpose |
|---|---|---|
| → Calls | `/skm sync` (inline Flow 1) | Step 2 absorbed the original sync flow (remote pull + skill diff) |
| → Reads | `.local/context_summary/`, `.local/docs/decision/`, `.local/docs/whiteboard/` | Step 3 work-state reconstruction |
| → Writes | `.local/collab/TODO.md` | Step 3 consolidates open items into TODO Pending block |
| ← Called by | None (user types `/hello` at conversation start) | — |
| ↔ Shared | `team/TODO.md` schema | Reconstruction must match `/team todo` format |
| ↔ Shared | `clean/` context_summary directory | Reads what `/clean` wrote in the previous session |

**Rename History (this skill only)**: absorbed `/skm sync` Flow 1 on 2026-04-24 — remote sync moved from `/skm` into `/hello` Step 2. Global rename history: see `_bootstrap/RENAME_HISTORY.md`.

---

Arguments: $ARGUMENTS
