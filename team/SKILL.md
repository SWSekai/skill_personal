---
name: team
description: "One-stop entry for interactive collaboration: AI TODO handling, live whiteboard, Markdown interactive decision tables, tech notes, handoff documents, work reports, and project journal maintenance. Subcommand routing: todo / board / decide / note / handoff / report / journal (renamed from living on 2026-04-24) / follow-up."
model: sonnet
effort: medium
argument-hint: "<todo|board|decide|note|handoff|report|journal|follow-up> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(git *), Bash(ls *), Bash(date *), Bash(mkdir *), Bash(mv *)
---

# /team — Interactive Collaboration Merged Skill

Integrates seven collaboration modes that interact with the user. The first argument determines the subcommand.

## Subcommand Routing

| Subcommand | Purpose | Corresponding Original Skill |
|---|---|---|
| `/team todo [add/list/<n>]` | Process AI TODO list | todo |
| `/team board [topic]` | Live whiteboard (consultation / planning conversations) | whiteboard |
| `/team decide <topic>` | Markdown interactive decision table | md-collab |
| `/team note [topic]` | Structured tech notes | tech-notes |
| `/team handoff` | Handoff document generation | handoff |
| `/team report [scope]` | Generate work reports from modify logs | report (moved from `/ask`) |
| `/team journal [view\|regen]` | Living document — accumulates outcomes from all board/decide closures | living (new) |
| `/team follow-up <file>` | Resume processing of an existing whiteboard / decision file | follow-up (new) |

When no argument is provided, ask the user to specify a subcommand.

---

## Common Rules (Apply to All Subcommands)

### Time Sampling (Mandatory)

**Before generating any file with a date stamp (whiteboard / decision / summary / handoff / modify_log), first call:**
```bash
date '+%Y-%m-%d %H:%M'
```
Use the Bash output as the authoritative date, not the context `currentDate` field (which may be stale across day boundaries).

### Filename Conventions

All interactive output files follow the pattern `YYMMDD_<topic>_<type>.md` where `<type>` indicates the file kind. See `references/naming.md` for the full table and rules.

### Closure Markers

- **File-level**: prepend `CLOSED_` to filename (e.g. `CLOSED_260422_topic_decision.md`)
- **Block-level**: append `✅` to block heading **or** embed `<!-- closed -->` in block body
- Parsers treat both markers as "skip this block"; Claude auto-adds `✅` if only `<!-- closed -->` is present (visual consistency)
- Details in `references/naming.md` §3

---

## A. `/team todo` — AI TODO Handling

### Usage

| Usage | Behavior |
|---|---|
| `/team todo` | Process pending items (by priority, highest first) |
| `/team todo add <desc>` | Quick add (supports `@high` / `@low`) |
| `/team todo list` | List all pending items |
| `/team todo <n>` | Process the specified item number |

### Triggers (CLAUDE.md Rule 17.1.1 / 17.1.7 / 17.1.8)

**Auto-capture** (silent, append to Pending, one-line tail hint in reply):
- User says `btw`, `順便`, `臨時想到`, `對了` → capture the mentioned item
- User signals **future trial**: `以後想試 X` / `未來可以做 X` / `將 X 加入代辦` / `之後可以試 X` → append to TODO (NOT decide); this is cross-project synchronized rule (Rule 17.1.7)

**Auto-create file**: if `.local/collab/TODO.md` does not exist on first TODO signal → Claude creates it with skeleton (`## Pending / ## In Progress / ## Completed`) automatically (Rule 17.1.8).

**Manual**: `/team todo add <desc>` explicit; `/team todo list`; `/team todo <n>`.

### Anti-patterns (when NOT to use TODO; Rule 17.1.9)

- ❌ User needs to choose A/B/C (互斥選項) → use `decide` or `AskUserQuestion` (Rule 17.1.2)
- ❌ Item requires multi-line design discussion (>200 chars or contains branching `?`) → propose upgrade to decide
- ❌ Already decided + in progress item described vaguely → ask follow-up first (Step 3)
- ❌ "Future trial" items being stuffed into decision tables as `[ ]` options → move to TODO, mark original as `~~~~（移往 TODO）`

### Step 1: Read and Parse

Read `.local/collab/TODO.md` (or the path specified by the project), parse all items in the "Pending" section, extract description, priority tag, and indented notes.
If the action is `add` / `list`, execute the corresponding branch and exit.

### Step 2: Sort and Select

Sort order: `@high` → unlabeled → `@low`; within the same priority, first-in-first-out. Print the sorted list and ask the user which items to process (defaults to item 1; can specify a number; can reply `all`).

### Step 3: Detail Confirmation (Follow-up Questions)

**Ask follow-ups**: vague description ("optimize performance" → which service? which endpoint?), multiple implementation approaches, unclear scope, missing acceptance criteria.
**Skip follow-ups**: already contains specific file/function/behavior; bug fix with error message; notes are sufficient.

Ask all questions at once. If the user replies "you decide", judge based on the existing architecture, state the decision in one sentence, then execute.

### Step 4: Execute

1. Move the item from Pending to In Progress:
   ```markdown
   ## In Progress
   - [~] description — processing (YYYY-MM-DD HH:MM)
   ```
2. Do the actual work (read code, modify, follow project conventions)
3. Derived tasks → automatically add to Pending, tag with `(derived from: ...)`
4. Blocked → pause, explain reason, move back to Pending and tag as blocker

### Step 5: Completion

```markdown
## Completed
- [x] description — done YYYY-MM-DD HH:MM
  - commit: `hash` message
  - affected: file1, file2
```

Selected `all` → continue to the next item; otherwise ask whether to continue.

### Step 6: Wrap-up

Present a processing summary (completed / deferred / derived). If there are uncommitted changes, remind the user they can invoke `/build commit`.

---

## B. `/team board` — Live Whiteboard

For consultation, planning, and troubleshooting conversations, create a continuously updated markdown document as a live whiteboard.

### Triggers (CLAUDE.md Rule 17.1 / 17.1.3)

**Auto-trigger** (tightened 2026-04-24 per Rule 17.1.3):
- Consultation / planning / troubleshooting conversation, AND
- **3 rounds of back-and-forth without convergence** (no clear TODO, no decide opened, no final answer)
- → auto-create `.local/docs/whiteboard/YYMMDD_<topic>_board.md`

1-2 rounds with quick convergence → inline answer, do NOT open whiteboard.

**Do not trigger** (anti-patterns per Rule 17.1.5/17.1.9):
- ❌ Pure code modification with clear task
- ❌ One-off Q&A (should answer in conversation, not archive)
- ❌ Execution work already scoped (should be in TODO)
- ❌ User needs to choose A/B/C (should be decide or AskUserQuestion)
- ❌ Quick follow-up to already-closed whiteboard (use `/team follow-up` instead)

### Step 1: Create the Whiteboard

- **First**: call `date '+%Y-%m-%d %H:%M'` to get authoritative time (see Common Rules)
- Path: `.local/docs/whiteboard/YYMMDD_<topic>_board.md` (snake_case topic; `_board` suffix is mandatory)
- Same topic on the same day → update the existing file, do not create another
- Structural principles:
  - **Pending**: pure checkbox list, see at a glance what remains
  - **Operation steps**: specific approaches numbered with § corresponding to pending items
  - **Completed**: one concise line per item; completed operation steps are removed at the same time

Initial templates can reference past whiteboards or be self-designed (no external assets needed).

### Step 2: Follow-up Dynamic Updates

Each time the user asks a follow-up or continues discussion:

1. **Read** the existing whiteboard
2. **Edit** incrementally (not overwrite):
   - Newly completed items: move from pending to completed, check off
   - New pending items: add to pending section
   - New decisions: add to decision log table
   - New notes: append to notes section
   - Update "Last Updated" date
3. Discussion direction shifts → add a new section, but keep the same document

### Step 3: Closure and Archival (Mandatory, Cannot Be Skipped)

> **This step is mandatory.** When the user indicates the discussion is concluded, all sub-steps below **must be completed in the same reply**.
> Forbidden: changing the status without renaming the file, or renaming without updating the living document, or leaving any step to the next reply.

#### 3.1 Change Status and Rename File

1. Update the document header status to **Completed** or **Paused**
2. Rename the file by prepending `CLOSED_` to the filename:
   - Before: `.local/docs/whiteboard/YYMMDD_<topic>_board.md`
   - After: `.local/docs/whiteboard/CLOSED_YYMMDD_<topic>_board.md`
   - Use: `mv .local/docs/whiteboard/YYMMDD_<topic>_board.md .local/docs/whiteboard/CLOSED_YYMMDD_<topic>_board.md`

#### 3.2 Append Inline Closure Summary (Mandatory, Unified Template)

Append the closure summary block at the bottom of the renamed file using the **unified template** in `references/naming.md` §5.2 (same format as `/team decide` Step 6.1):

```markdown
---

# 結案摘要（Closure Summary）

> **結案時間**：YYYY-MM-DD HH:MM
> **狀態**：✅ Completed / ⏸ Paused

## 背景
(Trigger reason, 1-3 sentences)

## 最終決策（whiteboard 重點決策逐項）
| 項目 | 結果 | 備註 |
|---|---|---|

## 變更清單
| 檔案 | 變更 |
|---|---|

## 🔖 保留候選（僅非單一路線適用）
(Write "無" if not applicable)

## 未解決遺留項
(None or list)
```

Whiteboard's key-outcomes / decisions-made / unresolved items map to the unified template as follows:
- **Key Outcomes** → append as 背景 + 變更清單
- **Decisions Made** → 最終決策 table
- **Unresolved Items** → 未解決遺留項

#### 3.3 Update Living Document (Mandatory)

After writing the closure summary, immediately update the project living document (`.local/docs/living/PROJECT_JOURNAL.md`):
- If the file does not exist, initialize it first (see Section G Step 1)
- Append a new row to the "討論成果" table: date, topic, 1–2 sentence outcome summary, link to renamed file
- If the whiteboard's decision log contains entries → also append to the "決策紀錄" table

#### 3.4 Self-Check

- [ ] File renamed with `CLOSED_` prefix
- [ ] "最後更新" date in the document updated
- [ ] Closure summary section appended
- [ ] Living document (`.local/docs/living/PROJECT_JOURNAL.md`) updated
- [ ] Daily report updated (Step 3.5)
- [ ] Contains reusable experience → evaluate writing it into a guide (same as `/build commit` Step 9)
- Any not done → complete immediately; must not end the reply

#### 3.5 Auto-Update Daily Report (Mandatory, silent)

After Step 3.3 living doc update, invoke `/team report --daily` flow inline (per `references/daily-report.md` §7.1):

1. Target: `.local/report/YYMMDD_daily_report.md` (today's date from `date '+%y%m%d'`)
2. Read this closed whiteboard's inline closure summary
3. Extract 「最終決策」 table → append to daily report's **「本日決策與討論結論」** section (one row per decision)
4. Extract 「背景」/「變更清單」 → append one-line entry to **「本日完成」**
5. Update daily report header: `> 最後更新：YYYY-MM-DD HH:MM | 來源：board closure (CLOSED_YYMMDD_<topic>_board.md)`
6. **Silent mode** — do NOT prompt for handoff (per decision §3.3.a); preserve §4 交接事項 section untouched
7. If daily report file does not exist → create from `assets/daily-report-template.md` and populate only §1, §5, §6-closure-record

Parser rules: `references/daily-report.md` §9.1 (closure block detection), §9.4 (section boundaries).

### Design Principles

- One discussion topic = one document
- Incremental update > overwrite
- Structured > stream-of-consciousness log
- Real-time: every reply should be reflected in the document
- Collapse upon completion: completed steps collapse to `~~title~~ ✅ Completed` + one line of result

---

## C. `/team decide` — Markdown Interactive Decision Table

Generate structured markdown for the user to check options, which Claude then reads back to implement.

### Triggers (CLAUDE.md Rule 17.1 / 17.1.2 / 17.1.7)

**Always manual — never auto-open** (Rule 17.1 table `自動觸發條件` row). Either:
- User explicitly requests decision document
- Chain transition: `board` reveals mutually-exclusive choices → open sub-decide referenced from whiteboard
- Chain transition: TODO item needs architectural decision (`@needs-decide` tag) → open decide

**Prefer AskUserQuestion instead** (Rule 17.1.2) when:
- A/B options are simple (color, preset, display preference)
- Each option description fits in 5 words
- No spec discussion, weigh-in, or current-state comparison needed
- → use `AskUserQuestion`; decision history is the conversation itself

**Open decide file** when:
- Options need weighing, pre-fill, current-state comparison, supplementary notes
- Multi-file / multi-module impact
- Skill / rule / workflow modification
- Resource trade-offs

### Anti-patterns (when NOT to use decide; Rule 17.1.5 / 17.1.9)

- ❌ Single-line bug fix (over-documentation)
- ❌ Simple A/B that could be `AskUserQuestion` (Rule 17.1.2)
- ❌ Informational lookup (goes to `ask info`)
- ❌ **Future trial items stuffed as `[ ]` options** (Rule 17.1.7): items like "以後想試 CNN model" are NOT mutually exclusive with other options — they belong in TODO. If closure finds such items in decide → move to TODO and mark original `~~~~（移往 TODO）`.

### Step 1: Analyze the Topic

- **Scan related code**: find existing implementations, config files, and APIs related to the topic
- **Identify decision items**: list all items requiring user decisions
- **Organize current state**: record each item's current status as a reference field

### Step 2: Generate Interactive Markdown

- **First**: call `date '+%Y-%m-%d %H:%M'` to get authoritative time (see Common Rules)
- Default location: `.local/docs/decision/YYMMDD_<topic>_decision.md` (snake_case topic; `_decision` suffix is mandatory; user can specify another path but the pattern is enforced)

Format specification:
- Checkboxes `[ ]` / `[x]`
- **Pre-filled recommended values**: pre-check based on analysis results to reduce user burden
- **Current-state column**: show current actual state for easy comparison
- **Continuous numbering**: global numbering across blocks (easy to reference verbally as "change item 17 to B")
- **Categorized grouping**: related items grouped into the same block, blocks separated by `---`
- Header semantics must be clear (not just A/B/C)
- **Each decision block must append a `supplementary note` field** (blockquote or empty `> _(please fill in)_`), allowing the user to freely write context, rationale, or counter-examples beyond the options; when reading decisions, the content of this field must also be parsed
- **[Mandatory] Branching questions must be broken into checkable options**: any question with conditional branches (e.g., "Can the data be sent externally?" with A/B/C as three possible answers) must be listed as multiple mutually-exclusive `[ ]` sub-items for the user to check; it is **forbidden** to write `[ ] condition description` followed by a blank for the user to type a string (e.g., `[not externally sendable]`). Free-form input format is limited to pure numeric / string input questions (e.g., "How many per day?")
- **[Mandatory] Free-form input questions must use unified syntax** `**答案**: ____________` (underscores as placeholder). When follow-up parses the file, empty underscore pattern is treated as unfilled; any other string is treated as the user's answer. See `references/followup.md` §6.

Supports four interaction modes:
- **Single-select matrix**: each row is an item, each column an option, one checkmark per row
- **Multi-select list**: each item can check multiple feature flags
- **Free-form input**: user types a string/number
- **Hybrid mode**: mix single-select and input fields within a table

### Step 3: Guide the User to Edit

```
Interactive configuration table created: `<path>`

Please open the file and check the setting values for each item according to the header instructions.
Pre-filled values are recommended configurations based on current state; adjust as needed.
When finished, reply "OK" or "Done", and I will read and implement.
```

### Step 4: Read the Decisions

1. Re-Read the file
2. Parse the check results
3. Compare differences against current state
4. Generate a change summary table:

   ```markdown
   ## Change Summary
   | # | Item | Current | → New |
   |---|---|---|---|
   | 3 | Annotation image menu | user | → view |
   ```

### Step 5: Confirm and Implement

1. Show the change summary to the user
2. Implement item by item (modify code/config)
3. After completion, compare against the original decision table to ensure nothing is missed

### Step 6: Inline Closure Summary + Decision File Cleanup (Mandatory, Cannot Be Skipped)

> **2026-04-22 revised**: replaces old "write to `.local/docs/summary/` + rename" flow with **inline closure summary** — append summary block to the end of the decision file itself, then rename `CLOSED_`.
> **This step is mandatory**. After Step 5 implementation completes, the inline summary + rename + living doc update **must be completed in the same reply**.
> Forbidden: replying to the user after implementation without appending the inline summary, leaving any sub-step to the next reply, waiting for the user to remind.

**Append first, rename second, update living third** (aligned with CLAUDE.md Rule 17):

#### 6.1 Append Inline Closure Summary (Mandatory)

Append the closure summary block to the **end of the existing decision file** (preserving all original §1-§n decision content, checkmarks, supplementary notes, and any Claude response blocks). Format per `references/naming.md` §5.2:

```markdown
---

# 結案摘要（Closure Summary）

> **結案時間**：YYYY-MM-DD HH:MM
> **狀態**：✅ 已執行
> **Commits**：`<hash>` (pending if not yet committed)

## 背景
(1-3 sentences on trigger reason)

## 最終決策（逐項目 §n.m）
| 項目 | 採納選項 | 備註 |
|---|---|---|

## 變更清單
| 檔案 | 變更 |
|---|---|

## 🔖 保留候選（僅非單一路線決策適用）
(If all blocks are single-path → write "無")

## 未解決遺留項
(None or list)
```

#### 6.2 Non-Single-Path Judgment (Mandatory, aligned with Rule 17)

For each decision block:
- **Single-path** (mutually exclusive, "選 A preclude B") → record only the adopted option; **do not** list unselected items
- **Non-single-path** (multi-select / "可複選") → list unselected options in the "🔖 保留候選" section of the inline summary, with:
  - Reason not selected
  - Restart timing
- Candidate cleanup: unvisited > 6 months or superseded → mark "已作廢", **do not delete** (historical record)
- New conversation with similar need → first read living doc's "🔖 保留候選" table; restart if applicable

#### 6.3 Rename the Decision File (Mandatory)

- **Proactively rename** `.local/docs/decision/YYMMDD_<topic>_decision.md` → `.local/docs/decision/CLOSED_YYMMDD_<topic>_decision.md`
  - Use: `mv .local/docs/decision/YYMMDD_<topic>_decision.md .local/docs/decision/CLOSED_YYMMDD_<topic>_decision.md`
- The `CLOSED_` prefix indicates the decision process is complete; the inline summary (appended in 6.1) is the authoritative record
- If the user explicitly says "delete the decision record" → delete instead and note it in the reply

#### 6.4 Update Living Document (Mandatory, Cannot Be Skipped)

After renaming, immediately update `.local/docs/living/PROJECT_JOURNAL.md`:
- If the file does not exist, initialize it first (see Section G Step 1)
- Append new row to "決策紀錄" table: date, topic, adopted options summary (1 line), link to `CLOSED_YYMMDD_<topic>_decision.md` (the **only** source file now — no separate summary file exists)
- If the inline summary contains "🔖 保留候選" → append each to living doc's "🔖 保留候選" table
- Update "最後更新" timestamp

#### 6.5 Self-Check (Mandatory)

After Step 6 completes, confirm:
- [ ] Inline closure summary has been appended to the end of `YYMMDD_<topic>_decision.md` (before rename)
- [ ] Inline summary includes: background, decision table (per §n.m item), change list, preserved candidates (if any non-single-path), leftover items
- [ ] `.local/docs/decision/YYMMDD_<topic>_decision.md` has been renamed to `CLOSED_YYMMDD_<topic>_decision.md`
- [ ] `.local/docs/living/PROJECT_JOURNAL.md` has been updated with this decision's entries (link → `CLOSED_*_decision.md`)
- [ ] **No** `.local/docs/summary/` file has been created (directory was removed 2026-04-22; writing there is a violation)
- [ ] Daily report updated (Step 6.6)
- Any not done → complete immediately; **must not end the reply**

#### 6.6 Auto-Update Daily Report (Mandatory, silent)

After Step 6.4 living doc update, invoke `/team report --daily` flow inline (per `references/daily-report.md` §7.2):

1. Target: `.local/report/YYMMDD_daily_report.md` (today's date from `date '+%y%m%d'`)
2. Read this closed decision file's inline closure summary (at file end)
3. Extract 「最終決策（逐項目 §n.m）」 table → append to daily report's **「本日決策與討論結論」** — collapse §n.m sub-items into one summary row
4. Extract 「變更清單」 → append entries to **「本日完成」** (one line per file change topic)
5. Update daily report header: `> 最後更新：YYYY-MM-DD HH:MM | 來源：decide closure (CLOSED_YYMMDD_<topic>_decision.md)`
6. **Silent mode** — do NOT prompt for handoff (per decision §3.3.a); preserve §4 交接事項 section untouched
7. If daily report file does not exist → create from `assets/daily-report-template.md` and populate only §1, §5, §6-closure-record

Parser rules: `references/daily-report.md` §9.1 (closure block detection), §9.4 (section boundaries).

### Design Principles

- Reduce cognitive load (pre-fill reasonable values)
- Global numbering for easy verbal reference
- Current state visible
- Structured output for easy subsequent parsing
- **Single-use**: clean up immediately after implementation; use the whiteboard for long-term tracking

---

## D. `/team note` — Tech Notes Organization

Organize technical Q&A from the conversation into structured notes, stored under `.local/docs/tech-note/`.

### Triggers

**Mode A (manual, primary)**: user explicitly specifies a topic.
Examples: "Organize a tech note on SQL JOIN", "Turn the earlier Git rebase discussion into an article".

**Mode B (detection reminder, passive)**: when the conversation is detected to contain a technical-knowledge-type Q&A, **do not generate directly**; first remind with a message:

> Detected a technical topic worth organizing: **{suggested topic}**. Organizing tech note now.

Execute only after user confirmation.

### Output Specification

- **Path**: `.local/docs/tech-note/`
- **Filename**: `{topic-category}_{specific-topic}.md` (e.g., `sql_comments.md`, `git_rebase.md`)
- **Format**: complete structured article, including TOC, architecture, and examples

```markdown
# {Topic Title}

> Created: YYYY-MM-DD | Last Updated: YYYY-MM-DD | Category: {category}

## Table of Contents
- [Overview](#overview)
- [Section One](#section-one)

## Overview
What this technology is, what problem it solves, and applicable scenarios

## {Section One}
### {Subsection}
Syntax explanation + complete runnable code example

## Common Pitfalls and Cautions
## Best Practices
## Further Reading
```

### Style

- Written in the project's language (by default aligned with the project's primary language)
- Each syntax point accompanied by a complete runnable example
- Annotate differences across environments/databases
- Like a tutorial article, not note fragments
- From shallow to deep: basics → advanced

### Flow

1. Confirm `.local/docs/tech-note/` exists
2. Check for an existing file on the same topic → if present, update and supplement; otherwise create a new one
3. Write a complete structured article
4. Inform the user of the file path

---

## E. `/team handoff` — Handoff and Environment Transition (Opus)

Before leaving (off-duty, vacation, project handover, environment switch), produce **two types of documents**: a human handoff document + an AI context bundle. The environment is **not destroyed** (difference from `/skm pack`: pack deletes the skill environment).

**This subcommand has an "evaluation / summarization / risk" nature, and it is recommended to invoke an Opus subtask via the Agent tool** (aligned with CLAUDE.md Rule 18).

### `/skm pack` vs `/team handoff` Differences

| Aspect | `/skm pack` | `/team handoff` |
|---|---|---|
| Purpose | Skill exit archival | Handoff / environment transition |
| Environment | **Clear** .claude/skills/ + Sekai_workflow/ + CLAUDE.md | **Preserve**, environment untouched |
| Output target | Machine (restore manifest) | Human (handoff doc) + AI (context bundle) |
| Output location | `.local/ai-context/` | `.local/docs/handoff/` or `docs/handoff/` (`--share`) |
| Use timing | Project end, long-term archival | Weekend off-duty, vacation, colleague takeover, switching dev machines |

### Triggers

| Usage | Behavior |
|---|---|
| `/team handoff` | Output to `.local/docs/handoff/` (local-only) |
| `/team handoff --share` | Output to `docs/handoff/` (under version control, colleagues can pull) |

### Step 1: Collect Project State

Read the following information sources in parallel:

| Information | Source | Purpose |
|---|---|---|
| Project overview | `CLAUDE.md` / root `README.md` | Human §A / AI bundle |
| Recent work | `.local/modify_log/*.md` (most recent 10~20) | Human §B |
| Pending items | `.local/collab/TODO.md` | Human §C |
| Plans in progress | `.local/docs/plan/*.md` (unfinished steps) | Human §C |
| Risk records | "Potential risks" sections in `.local/modify_log/` | Human §D |
| Environment architecture | `docker-compose.yml` / `.env` / config | Human §E / AI bundle |
| Git status | `git status` / `git log origin..HEAD` / `git branch` | Human §F |
| Decision history | `.local/docs/summary/*.md` | AI bundle |
| Memory | `~/.claude/projects/<proj>/memory/*.md` | AI bundle |
| Experience guides | `.local/docs/guide/*.md` | AI bundle |
| Context summaries | Latest in `.local/context_summary/` | AI bundle |

### Step 2: Generate Human Handoff Document (`YYMMDD_handoff.md`)

```markdown
# Project Handoff Document

> Generated: YYYY-MM-DD HH:MM
> Generated by: Claude (/team handoff)
> Project: <PROJECT_NAME>

---

## A. Project Overview

(Extract 3–5 sentences from CLAUDE.md / README so someone unfamiliar can quickly understand what the project does)

## B. Current Progress

### Completed (recent)
(Group by functional area from modify_log, 1–2 sentence summary per group)

| Functional area | Completed items | Last commit |
|---|---|---|

### In Progress
(WIP branches, unfinished plan steps, In Progress items in TODO)

## C. Planned Items

### Priority Recommendations
(Integrated from TODO + plan unfinished steps, sorted by priority)

| # | Item | Source | Priority | Estimated complexity |
|---|---|---|---|---|

### Takeover Recommendations
(If a colleague is taking over, suggest where to start; if it's your own return, remind of the most critical resume point)

## D. Known Risks and Blockers

| Risk | Source | Impact | Suggested handling |
|---|---|---|---|

## E. Environment Information

### Docker Services
| Service | Port | Start command | Notes |
|---|---|---|---|

### Key Connections
| Type | Key | Source | Value |
|---|---|---|---|
| DB | DB_HOST | .env | *** |

(Env variable values are universally masked as `***`, only key + source is listed; if the project has no Docker, omit)

### Third-party Integrations
| Service | Purpose | Config source |
|---|---|---|

## F. How to Resume Work

1. **Branch**: currently on `<branch>`, upstream is `<remote/branch>`
2. **Start services**: `docker compose up -d` (list required services)
3. **Unpushed changes**: yes/no (if yes, list commits)
4. **Uncommitted changes**: yes/no (if yes, list files)
5. **Environment prep**: env vars to set / migrations to run
6. **First step**: what to do first after takeover (specific to file + action)

## G. AI Context Bundle

This handoff also produces an AI-readable context bundle at `YYMMDD_ai-context/` in the same directory.
At the start of a new conversation, instruct the AI to read that directory to quickly restore project knowledge.
```

### Step 3: Generate AI Context Bundle (`YYMMDD_ai-context/`)

Create a subdirectory in the same location as the handoff document, collecting everything the AI needs to quickly grasp the project:

```
YYMMDD_ai-context/
├── CLAUDE.md                  ← Project spec snapshot
├── project-summary.md         ← AI-only summary (template below)
├── memory/                    ← Memory snapshot (*.md)
├── decision-history/          ← Copy of .local/docs/summary/*.md
├── guides/                    ← Copy of .local/docs/guide/*.md
├── recent-modify-logs/        ← Most recent 10 from .local/modify_log/
├── todo-snapshot.md           ← Copy of .local/collab/TODO.md
└── context-snapshot.md        ← Latest summary from .local/context_summary/
```

#### `project-summary.md` (AI-only, generated by Opus summarization)

```markdown
# AI Quick-Start: Project Fast-Onboarding Guide

> This document is for the AI (Claude) to quickly restore project knowledge in a new conversation; not for human reading.
> Generated: YYYY-MM-DD HH:MM

## Project Positioning and Architecture
(Distilled from CLAUDE.md + README: what the project does, tech stack, service topology)

## Current Status
(WIP / completed milestones / next step)

## Decision History Summary
(Distill one-line summaries of each decision from .local/docs/summary/*.md + preserved-candidate hints)

| Date | Decision | Adopted option | Has preserved candidates? |
|---|---|---|---|

## Conventions and Preferences
(Distilled from Memory: commit format, language preference, model tiering, flowback switch state, etc.)

## Known Pitfalls
(Distilled from guides + risk sections of modify_log: pits encountered + hint to solutions)

## Environment Snapshot
(Docker / DB / env key list — values masked)
```

### Step 4: Output and Confirmation

1. Write the human handoff document:
   - Default: `.local/docs/handoff/YYMMDD_handoff.md`
   - `--share`: `docs/handoff/YYMMDD_handoff.md`
2. Write the AI context bundle to `YYMMDD_ai-context/` in the same directory
3. Inform the user of both output paths
4. If `--share`: hint that they can `git add docs/handoff/` to push to colleagues
5. Hint: "In a new conversation, instruct the AI to read the `YYMMDD_ai-context/` directory to quickly restore knowledge"

### Design Principles

- **Dual audience**: human document (colleague-friendly) + AI document (restore knowledge in new conversation)
- **Environment non-destruction**: the biggest difference from `/skm pack` — after handoff the user can continue working
- **Mask sensitive values**: env variables list keys only, not values
- **Actionable**: every section ends with a "next step suggestion"
- **Decision traceability**: the AI bundle contains full decision history, so a new AI can look up preserved candidates instead of redesigning

---

## F. `/team report` — Work Report Generation

Consolidate project modify logs into a work report suitable for a **2–3 minute briefing**. (Moved here from `/ask report` on 2026-04-17.) 2026-04-24 added `--daily` flag for daily Teams-renderable daily report (full spec in `references/daily-report.md`).

### Triggers

| Usage | Behavior |
|---|---|
| `/team report` | Full report (all modify logs) |
| `/team report weekly` | Weekly report (past 7 days) |
| `/team report YYMMDD YYMMDD` | Specified range |
| `/team report --daily` | **Daily Teams report (today)** — details in `references/daily-report.md` |
| `/team report --daily YYMMDD` | Daily Teams report for specified day |
| `/team report --daily YYMMDD YYMMDD` | Teams daily report for specified range (aggregated) |

If `--daily` is present, branch to the daily report flow (`references/daily-report.md`). Otherwise continue with the formal report flow below.

### Step 1: Determine the scope

- `--daily` present → switch to daily report flow per `references/daily-report.md` and skip Steps 2–4 below
- No argument / `full` → read everything
- `weekly` → past 7 days (filter by date prefix in filename)
- `YYMMDD YYMMDD` → specified range

Source: `.local/modify_log/`

### Step 2: Read and analyze

Read each modify log within the scope and extract:
- Change topic and category
- Affected files and services
- Technical highlights
- Potential risks and items to track

### Step 3: Generate the report

**Filename rules**:
- Full: `YYMMDD_full_report.md`
- Weekly: `YYMMDD_weekly_report.md`
- Range: `YYMMDD_report_[start]_to_[end].md`

**Report structure** (optimized for a 2–3 minute briefing):

```markdown
# [Project Name] Development Progress Report

> Report date: YYYY-MM-DD
> Coverage period: YYYY-MM-DD ~ YYYY-MM-DD
> Modify log count: N entries

## 1. Key Achievements Summary
(2–3 sentences summarizing the period's workload and core direction — grasp the whole picture in 30 seconds)

## 2. Feature Development Categorized Summary
(Group by functional area; each group uses a table listing items + one-sentence description)

| Item | Description |
|---|---|

## 3. Key Technical Highlights
(3–5 bullets highlighting noteworthy technical decisions or design patterns)

## 4. Affected Services and Containers

| Service | Item Count | Main Changes |
|---|---|---|

## 5. Items to Track
(Known risks, incomplete items, features needing follow-up verification)
```

### Step 4: Output

Write to `.local/report/`.

### Writing Principles

1. **Briefing-oriented**: Each section deliverable in 30 seconds
2. **Tables first**: Use tables instead of long narrative text
3. **Clear categorization**: Group by functional area, **not** chronologically
4. **Concise technical highlights**: Pick only 3–5
5. **Actionable tracking items**: Be specific; avoid "continue to optimize"
6. **Language**: Align with project conventions (per project language setting, e.g., Traditional Chinese for Taiwan)

### `--daily` Mode (Daily Report)

When `--daily` flag is present, execute the daily report flow fully defined in `references/daily-report.md`. Key differences vs default mode:

- **Output**: `.local/report/YYMMDD_daily_report.md` (one per day, smart-update)
- **Sources**: whiteboard/decision closure summaries + TODO deltas + modify_log + user handoff
- **Sections**: 本日完成 / 進行中 / 待辦與阻塞 / 交接事項 / 本日決策與討論結論 / 作業記錄
- **Format**: Teams-safe markdown subset with `- [ ]` checkboxes
- **Triggers**: manual + auto-called from board closure (§B Step 3.5), decide closure (§C Step 6.6), and `/commit-push` Step 11
- **Handoff**: prefer `@handoff:<name>` tags in TODO.md; fallback to AskUserQuestion on manual trigger only
- **Integrity**: cross-check `git log` vs `.local/modify_log/` — commits without modify_log marked ⚠️
- **Cross-day**: `/hello` Step 3.4 surfaces yesterday's unresolved handoffs and missing modify_logs

> ⚠️ **MANDATORY — Audience & Writing Style** (see `references/daily-report.md` §4.0):
> Daily report is written for the **supervisor / external stakeholder**, not as a dev diary. Before writing any entry:
> - Lead with outcomes, not implementation
> - No function names / flag names / parameter values / decision-doc paths in body text (those belong in `modify_log` / appendix)
> - Quantify with the team's KPI (e.g. `Recall 37.7→44.6% (+6.9 pp)`), not "大幅改善"
> - Never mention Claude Code internals, model tiers, context modes, or flow interruptions
> - Reading test: an outside reader grasps progress in under 60 seconds
> This rule applies to **all** triggers — manual, board closure, decide closure, and `/commit-push` Step 11 auto-populate.

Full rules, parser specs, edge cases: `references/daily-report.md`. Template: `assets/daily-report-template.md`.

---

## G. `/team journal` — Project Journal Maintenance (renamed from `/team living` on 2026-04-24)

Maintain a single, continuously updated project-level document that accumulates outcomes from all whiteboard and decision table closures. Acts as the project's authoritative knowledge base for past discussions, decisions, and preserved candidates.

**This subcommand is primarily auto-called** by `/team board` Step 3.3 and `/team decide` Step 6.4. Manual invocation is supported for viewing or regenerating.

### Triggers (CLAUDE.md Rule 17.1)

- **Auto**: `/team board` closure Step 3.3 + `/team decide` closure Step 6.4 → append one row to the appropriate journal table
- **Manual**: `/team journal` (show path) / `/team journal view` (print full) / `/team journal regen` (rebuild from CLOSED_* files)

### Anti-patterns (Rule 17.1.5 / 17.1.9)

- ❌ Manual editing of `PROJECT_JOURNAL.md` (violates auto-index principle) — use CLOSED_ source file edits instead, then `/team journal regen`
- ❌ Using journal as TODO replacement (journal is read-only historical index)
- ❌ Using journal for daily work accumulation (that's `/team report --daily`)

### Document Location

`.local/docs/living/PROJECT_JOURNAL.md`

One file per project; entries are append-only (never overwrite existing rows).

### Triggers

| Usage | Behavior |
|---|---|
| `/team journal` | Show the living document path and last-update timestamp |
| `/team journal view` | Print the full living document |
| `/team journal regen` | Rebuild the document from all `CLOSED_*` source files |

### Step 1: Initialize (First-Time Only)

If `.local/docs/living/PROJECT_JOURNAL.md` does not exist, create the directory and initialize the file:

```markdown
# 專案活文件（Project Journal）

> 建立：YYYY-MM-DD
> 最後更新：YYYY-MM-DD HH:MM
> 專案：<project-name>（from directory name or CLAUDE.md）

---

## 決策紀錄

| 日期 | 主題 | 最終決策摘要 | 來源文件 |
|------|------|------------|---------|

---

## 討論成果

| 日期 | 主題 | 關鍵成果 | 來源文件 |
|------|------|---------|---------|

---

## 🔖 保留候選（未採納但可重啟）

| 來源主題 | 選項說明 | 未採納原因 | 重啟時機 |
|---------|---------|----------|---------|
```

### Step 2: Append from Board Closure

Called internally after `/team board` Step 3.2. Input: the renamed whiteboard file path.

1. Read the closure summary section from `CLOSED_YYMMDD_topic.md`
2. Append one row to the "討論成果" table:
   - Date (from file or closure summary)
   - Topic (from filename or whiteboard title)
   - Key outcomes (1–2 sentences condensed from "Key Outcomes" bullet points)
   - Link: `[CLOSED_YYMMDD_topic.md](.local/docs/whiteboard/CLOSED_YYMMDD_topic.md)`
3. If the whiteboard's "決策紀錄" table has entries → also append each to "決策紀錄" table
4. Update "最後更新" timestamp

### Step 3: Append from Decide Closure

Called internally after `/team decide` Step 6.4. Input: the renamed decision file path (no separate summary file exists — summary is inline at file end).

1. Read the **inline closure summary block** at the bottom of `CLOSED_YYMMDD_<topic>_decision.md`
2. Append rows to the "決策紀錄" table — one row per major decision block:
   - Date, topic, adopted option summary (1 line), link **only** to `CLOSED_YYMMDD_<topic>_decision.md` (the inline summary inside is the authoritative record)
3. If the inline summary contains "🔖 保留候選" section → append each candidate to living doc's "🔖 保留候選" table
4. Update "最後更新" timestamp

### Step 4: Regen Flow

For `/team journal regen`:
1. Clear the rows from all three tables (keep headers and template structure)
2. Scan all `CLOSED_*` files in `.local/docs/whiteboard/` and `.local/docs/decision/`
3. For each CLOSED file, parse the **inline closure summary block** at its end
4. Rebuild the three tables chronologically by date
5. Report: "Rebuilt from N whiteboard sessions, M decisions"

Note: `.local/docs/summary/` directory no longer exists (removed 2026-04-22). Do not scan it.

### Design Principles

- **Append-only**: entries are added, never deleted (permanent historical record)
- **One file per project**: complete picture of all outcomes in one place
- **Auto-updated on closure**: no manual maintenance needed — board and decide call it automatically
- **Preserved candidates visible**: the 🔖 section surfaces prior unselected options before redesigning
- **Linked to source**: every entry links back to the renamed `CLOSED_*` file for drill-down

---

## H. `/team follow-up` — Resume Board / Decision File Processing

Re-enter the processing flow of an existing whiteboard or decision file without retyping context. The user supplies only a filename (or prefix); Claude locates the file, parses it, and continues.

### Usage

| Usage | Behavior |
|---|---|
| `/team follow-up <file>` | Resume processing of the specified file |
| `/team follow-up` | No argument → list recent 5 non-closed files, let user select |

Filename accepts: full name, no-extension form, or prefix (e.g. `260422_team` matches one of the day's files). Full matching rules and multi-candidate UI are in `references/followup.md` §2.

### Step 1: Parse argument + locate file

1. Apply matching strategy (see `references/followup.md` §2)
2. Search scope: `.local/docs/whiteboard/` + `.local/docs/decision/`
3. **Filter out `CLOSED_*` files silently** at candidate listing stage
4. Exact-typed `CLOSED_xxx` → special-case message "file is closed, see summary at …"
5. Zero matches → list nearest 3 candidates via AskUserQuestion
6. Multiple matches → list all candidates via AskUserQuestion (type suffix > directory > mtime)

### Step 2: Dispatch by file type

Detected via filename suffix (`_board` vs `_decision`) with directory as fallback:

| Type | Handler | Reference |
|---|---|---|
| `_board.md` in `.local/docs/whiteboard/` | whiteboard follow-up handler | `references/followup.md` §4 |
| `_decision.md` in `.local/docs/decision/` | decision follow-up handler | `references/followup.md` §3 |

### Step 3: Parse (skip closed blocks)

For each `##` / `###` block:
- Heading contains `✅` **or** body contains `<!-- closed -->` → skip (and auto-add `✅` if only `<!-- closed -->` is present, for visual consistency)
- Otherwise → parse checkboxes, supplementary notes, and free-form input (`**答案**: ____`)

### Step 4: Handler-specific actions

**Decision file**:
1. Detect mutually-exclusive double-check violations → pause and list conflicts
2. Detect unchecked single-path blocks → pause and mark block IDs
3. Scan supplementary notes for new requirements (imperative verbs like 請/要/need/must) → list as "new requirements" in change summary
4. Free-form input unfilled (`**答案**: ____`) → AskUserQuestion to collect, Edit file with answer
5. Generate change summary → proceed to implementation
6. On completion → run `/team decide` Step 6 closure flow (summary + rename + living doc)

**Whiteboard file**:
1. Collect all non-closed Pending items
2. AskUserQuestion: which item to advance? (include "just load context" option)
3. Item chosen → do the work, mark item completed in whiteboard
4. "Just load context" chosen → load file into context, no further action

### Step 5: Error boundaries

See `references/followup.md` §9 for: directory-as-argument, path traversal, malformed files, duplicate section IDs, "Other" in AskUserQuestion.

### Design Principles

- **Context-free resumption**: one filename = full flow re-entry
- **Silent closed-file filtering**: `CLOSED_*` never appears in candidates unless typed exactly
- **Block-level closure respected**: both `✅` and `<!-- closed -->` markers skip blocks
- **UI consistency**: all disambiguation uses AskUserQuestion (aligns with CLAUDE.md Rule 15)
- **Reference-backed**: this section is the contract; `references/followup.md` is the implementation spec

---

Arguments: $ARGUMENTS (the first token is the subcommand, the rest are arguments for that subcommand)
