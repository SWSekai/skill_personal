---
name: team
description: "One-stop entry for interactive collaboration: AI TODO handling, live whiteboard, Markdown interactive decision tables, tech notes, handoff documents, work reports, and living document maintenance. Subcommand routing: todo / board / decide / note / handoff / report / living."
model: sonnet
effort: medium
argument-hint: "<todo|board|decide|note|handoff|report|living> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(date *), Bash(mkdir *), Bash(mv *)
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
| `/team living [view\|regen]` | Living document — accumulates outcomes from all board/decide closures | living (new) |

When no argument is provided, ask the user to specify a subcommand.

---

## A. `/team todo` — AI TODO Handling

### Usage

| Usage | Behavior |
|---|---|
| `/team todo` | Process pending items (by priority, highest first) |
| `/team todo add <desc>` | Quick add (supports `@high` / `@low`) |
| `/team todo list` | List all pending items |
| `/team todo <n>` | Process the specified item number |

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

### Triggers

**Auto-trigger**: the conversation involves system consultation, solution evaluation, problem troubleshooting, or discussion requiring multi-step progress tracking.
**Do not trigger**: pure code modification, one-off Q&A, execution work with a clearly defined task.

### Step 1: Create the Whiteboard

- Path: `.local/docs/whiteboard/YYMMDD_topic-description.md`
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
   - Before: `.local/docs/whiteboard/YYMMDD_topic.md`
   - After: `.local/docs/whiteboard/CLOSED_YYMMDD_topic.md`
   - Use: `mv .local/docs/whiteboard/YYMMDD_topic.md .local/docs/whiteboard/CLOSED_YYMMDD_topic.md`

#### 3.2 Append Closure Summary to File (Mandatory)

Append a `## Closure Summary` section at the bottom of the renamed file:

```markdown
## Closure Summary

> Closed: YYYY-MM-DD HH:MM
> Status: ✅ Completed / ⏸ Paused

### Key Outcomes
(2–4 bullet points of the core conclusions reached)

### Key Decisions Made
| Decision | Result |
|---|---|

### Unresolved Items
(Write "None" if none; or list items deferred to TODO or a follow-up session)
```

#### 3.3 Write Complete Summary Entry into PROJECT_JOURNAL.md (Mandatory)

After writing the whiteboard's Closure Summary (3.2) and renaming the file (3.1), immediately append a complete `###` entry into `.local/docs/living/PROJECT_JOURNAL.md` under the appropriate functional `##` section.

**Entry format** (same five-element template as decide Step 6.1):

```markdown
### YYYY-MM-DD — <Topic>

**背景**：(1–3 sentences — what the discussion set out to explore)

**最終決策**：(rows from the whiteboard's decision log; or "無（純探索）" if exploratory)
| § | 選項 | 採用 |
|---|---|---|

**變更清單**：(files touched as a result of the discussion, or "無（僅討論）")
| 檔案 | 變更 |
|---|---|

**🔖 保留候選**：(options raised but not taken; write "無" if none)
- **候選 X**：...
  - 未採納原因：...
  - 重啟時機：...

**遺留項**：(from Closure Summary's Unresolved Items; "無" if none)

**來源**：[`CLOSED_YYMMDD_<topic>.md`](../whiteboard/CLOSED_YYMMDD_<topic>.md)
```

**Integrity requirement**: entry must be self-contained — the reader understands the full outcome without opening `CLOSED_*.md`. Separate `summary/*.md` files are **not produced** (flow aligned with decide Step 6).

Update `> 最後更新：` timestamp in PROJECT_JOURNAL.md header.

#### 3.4 Self-Check

- [ ] File renamed with `CLOSED_` prefix
- [ ] "最後更新" date in the document updated
- [ ] Closure summary section appended to the renamed file
- [ ] PROJECT_JOURNAL.md contains a new `###` entry with all five required elements (背景／決策／變更／保留候選／遺留項), placed under the correct functional `##` section
- [ ] Entry back-references `CLOSED_*.md` via relative link
- [ ] Contains reusable experience → evaluate writing it into a guide (same as `/build commit` Step 9)
- Any not done → complete immediately; must not end the reply

### Design Principles

- One discussion topic = one document
- Incremental update > overwrite
- Structured > stream-of-consciousness log
- Real-time: every reply should be reflected in the document
- Collapse upon completion: completed steps collapse to `~~title~~ ✅ Completed` + one line of result

---

## C. `/team decide` — Markdown Interactive Decision Table

Generate structured markdown for the user to check options, which Claude then reads back to implement.

### Step 1: Analyze the Topic

- **Scan related code**: find existing implementations, config files, and APIs related to the topic
- **Identify decision items**: list all items requiring user decisions
- **Organize current state**: record each item's current status as a reference field

### Step 2: Generate Interactive Markdown

Default location `.local/docs/decision/<topic>.md`; user can specify another.

Format specification:
- Checkboxes `[ ]` / `[x]`
- **Pre-filled recommended values**: pre-check based on analysis results to reduce user burden
- **Current-state column**: show current actual state for easy comparison
- **Continuous numbering**: global numbering across blocks (easy to reference verbally as "change item 17 to B")
- **Categorized grouping**: related items grouped into the same block, blocks separated by `---`
- Header semantics must be clear (not just A/B/C)
- **Each decision block must append a `supplementary note` field** (blockquote or empty `> _(please fill in)_`), allowing the user to freely write context, rationale, or counter-examples beyond the options; when reading decisions, the content of this field must also be parsed
- **[Mandatory] Branching questions must be broken into checkable options**: any question with conditional branches (e.g., "Can the data be sent externally?" with A/B/C as three possible answers) must be listed as multiple mutually-exclusive `[ ]` sub-items for the user to check; it is **forbidden** to write `[ ] condition description` followed by a blank for the user to type a string (e.g., `[not externally sendable]`). Free-form input format is limited to pure numeric / string input questions (e.g., "How many per day?")
- **[Mandatory] Multi-select questions must include an "all" option** (2026-04-22 added): for multi-select questions (non-mutually-exclusive, can check multiple items), if there is no resource conflict or implementation cost trade-off between options, Claude **must** append `★ 全部都做` as the final checkbox (equivalent to selecting all). Rationale: "do them all" is a common final intent; pre-providing it reduces user cognitive load. **Exempt**: single-select, mutually-exclusive groups, or questions where options have significant resource/time trade-offs that require individual weighing.

Supports four interaction modes:
- **Single-select matrix**: each row is an item, each column an option, one checkmark per row
- **Multi-select list**: each item can check multiple feature flags
- **Free-form input**: user types a string/number
- **Hybrid mode**: mix single-select and input fields within a table

**`(已確認)` section-header convention** (2026-04-17 added):
- User appends `(已確認)` to a finalized section header (e.g., `## §1 後端確認策略 (已確認)`)
- Signals to Claude: "this block is settled; skip re-analysis and Q&A scanning"
- User removes the tag if they update the section and want Claude to re-examine it
- Token-saving mechanism: avoids re-processing stabilized content on every reload

### Step 3: Guide the User to Edit

```
Interactive configuration table created: `<path>`

Please open the file and check the setting values for each item according to the header instructions.
Pre-filled values are recommended configurations based on current state; adjust as needed.
When finished, reply "OK" or "Done", and I will read and implement.
```

### Step 3.5: 補充說明 Round-Trip (In-File Q&A) — Mandatory

**`(已確認)` sections are exempt** (2026-04-17 added): before scanning `補充說明` fields, check whether the section header ends with `(已確認)`. If yes, skip that section entirely — no scanning, no in-file response. The user removes the tag if they want Claude to re-examine.

**Superseded rounds collapse to `<details>` toggle** (2026-04-17 added, revised): when writing a NEW Claude 回覆 that supersedes a prior round in the same `補充說明` block (user's question changed / decision flipped / previous answer obsolete), wrap the older round(s) in `<details>`.

**Critical syntax rules** (violating these will prevent the toggle from rendering in VSCode preview / GitHub / most markdown-it renderers):

1. `<details>`, `<summary>`, `</details>` tags MUST be at document top-level — **no `>` blockquote prefix**
2. Markdown content inside `<details>` needs a **blank line** (truly empty, no `>` prefix) between `<summary>` and the first content line, and another blank line before `</details>`
3. Content inside MAY use `>` blockquote for visual styling, but the HTML tag lines themselves must not

Correct form:

```markdown
(end of current blockquote — last line may still have > prefix)

<details>
<summary>⬇ Claude 回覆（YYYY-MM-DD，第 N 輪 — 一句話說明已被什麼取代）</summary>

> (older round content — content lines keep `>` for blockquote styling)
> (more content)

</details>

---
```

Keep the current round visible before `<details>`. Rationale: reduces rendered length and keeps the current answer immediately scannable while preserving history for audit.

**Completed section wrap** (2026-04-17 added): when an entire section's decisions are finalized **AND** any implementation path is closed (code done or explicitly postponed), wrap the whole section (including the `##` header) in `<details>` to visually compress the document. Summary text should include the section name so clicking still navigates conceptually.

```markdown
<details>
<summary>§N SectionName — ✅ 已確認（一行說明，例如 "code A1 已實作"）</summary>

## §N SectionName (已確認)

(full section content — table, 補充說明 blockquote, nested <details> history, etc.)

</details>

---
```

Rules:
- Also append `(已確認)` to the `##` header so Claude's Step 3.5 skip-scan still applies
- **Do not** wrap sections that still have pending actions (e.g., backend coordination, unchecked decisions, action items the user must carry out)
- Claude proposes which sections qualify when user asks; Claude does **not** auto-wrap — user confirms scope first

When the user writes a question, clarification request, or asks for a recommendation **inside a `補充說明` field** (detected by: `?` / `？` / `請說明` / `請詳細` / `進一步說明` / `請解釋` / `你建議` / `你認為` / references to undefined terms), Claude **must answer by editing that same `補充說明` field in the decision file**, NOT by replying in chat only.

**Rationale**: the decision table is the single source of truth for this interaction. Chat messages are ephemeral and scroll away; in-file answers stay attached to the exact decision block they concern, preserve reviewability, and match the spirit of an interactive document.

**Response format** (append inside the existing `補充說明` blockquote; do NOT overwrite the user's original note):

```markdown
> **補充說明**
> > _(使用者原文保留)_
>
> **Claude 回覆（YYYY-MM-DD）**
>
> (content: markdown tables / file:line refs / recommendations, written inside the blockquote)
```

**When Claude has a recommendation for an un-checked decision row** (e.g., `[ ] [ ] [ ]`):

- Write the recommendation and reasoning **into the 相關 `補充說明`** (prose or table form)
- **Do NOT pre-check `[x]` on behalf of the user** — the checkbox represents the user's authorization, not Claude's judgment
- End with a call-to-action: `"請勾選後回覆 OK，我再開始實作"`

**Chat reply on this turn**: one short pointer only — e.g., `"已寫入 §1/§3/§5 補充說明，請查閱決策表"`. Do NOT duplicate the content in chat.

### Step 4: Read the Decisions

1. Re-Read the file
   - Sections marked `(已確認)` → parse checkbox results only; do not re-read or re-evaluate supplementary notes (2026-04-17 added)
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

### Step 6: Integrate Summary into PROJECT_JOURNAL.md + Rename Decision File (Mandatory, Cannot Be Skipped)

> **This step is mandatory**. After Step 5 implementation completes, all sub-steps **must be completed in the same reply**.
> Forbidden: replying to the user directly after implementation without updating PROJECT_JOURNAL.md, leaving the integration to the next reply, waiting for the user to remind before doing it.

**New flow (2026-04-22 revised)**: summary content is written **directly into `PROJECT_JOURNAL.md`** as a complete entry within the appropriate functional section. Separate `summary/*.md` files are **no longer produced** — they were a level of indirection; integrating full summaries into the journal makes it self-contained as the project overview.

#### 6.1 Write Complete Summary Entry into PROJECT_JOURNAL.md (Mandatory)

Target file: `.local/docs/living/PROJECT_JOURNAL.md` (if not exists, initialize per Section G Step 1).

**Decide where to append**: identify the functional section (`## <Functional Area>`, e.g., `## OCR Pipeline`, `## Skill 規則`, `## Setup`) that this decision belongs to. If no matching section exists, create a new one and add it to the table of contents.

**Append one complete `###` entry** at the top of that section (newest first):

```markdown
### YYYY-MM-DD — <Topic>

**背景**：
(Reason for trigger, 1–3 sentences — what prompted this decision, what problem it addresses)

**最終決策**：
| § | 選項 | 採用 |
|---|---|---|
(One row per decision block, fully listing adopted options)

**變更清單**：
| 檔案 | 變更 |
|---|---|

**🔖 保留候選**（未採納但可重啟）：
(Required only for non-single-path decisions — see 6.2; write "無" if single-path)
- **候選 X**：<description>
  - 未採納原因：...
  - 重啟時機：...

**遺留項**：
(Write "無" if none; or list items deferred to TODO or a follow-up session)

**來源**：[`CLOSED_<topic>.md`](../decision/CLOSED_<topic>.md)
```

**Integrity requirement**: all five elements (背景／決策／變更／保留候選／遺留項) must be present — readers should not need to jump to `CLOSED_*.md` to understand what was decided. `CLOSED_*.md` is for drill-down into interaction history (checkbox trails, 補充說明 rounds), not for the decision itself.

#### 6.2 Non-Single-Path Judgment (Mandatory)

Determine whether each set of decision options is mutually exclusive:
- Picking A precludes B → **single-path** → only record the final choice in the entry's 最終決策 table
- Multiple can coexist → **non-single-path** → retain unselected options in the entry's 🔖 保留候選 block
- Candidate cleanup: unvisited for over 6 months or superseded by a new decision → mark as `(deprecated)`, **do not delete** from PROJECT_JOURNAL.md
- When a new conversation has a similar need → first grep PROJECT_JOURNAL.md 🔖 blocks; restart if possible

#### 6.3 Rename the Decision File (Mandatory)

- **Proactively rename** `.local/docs/decision/<topic>.md` → `.local/docs/decision/CLOSED_<topic>.md`
  - Use: `mv .local/docs/decision/<topic>.md .local/docs/decision/CLOSED_<topic>.md`
- `CLOSED_*.md` retains the **full interactive history** (checkboxes, 補充說明 rounds, Claude replies) — for readers who need to drill into "why this path, what was considered"
- PROJECT_JOURNAL.md provides the **converged summary** — for readers who need "what was done"
- If the user explicitly says "delete the decision record" → delete instead and note it in the reply

#### 6.4 Update "最後更新" Timestamp (Mandatory)

Update the header line `> 最後更新：YYYY-MM-DD HH:MM` in PROJECT_JOURNAL.md.

#### 6.5 Self-Check (Mandatory)

After Step 6 completes, confirm:
- [ ] PROJECT_JOURNAL.md contains a new `###` entry with all five required elements (背景／決策／變更／保留候選／遺留項)
- [ ] Entry is placed under the correct functional `##` section (create new section if none exists; add to TOC)
- [ ] Entry back-references `CLOSED_<topic>.md` via relative link
- [ ] `.local/docs/decision/<topic>.md` has been renamed to `CLOSED_<topic>.md`
- [ ] PROJECT_JOURNAL.md "最後更新" timestamp has been refreshed
- Any not done → complete immediately; **must not end the reply**

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

Before leaving (off-duty, vacation, project handover, environment switch), produce **two types of documents**: a human handoff document + an AI context bundle. The environment is **not destroyed** (difference from `/skill pack`: pack deletes the skill environment).

**This subcommand has an "evaluation / summarization / risk" nature, and it is recommended to invoke an Opus subtask via the Agent tool** (aligned with CLAUDE.md Rule 18).

### `/skill pack` vs `/team handoff` Differences

| Aspect | `/skill pack` | `/team handoff` |
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
- **Environment non-destruction**: the biggest difference from `/skill pack` — after handoff the user can continue working
- **Mask sensitive values**: env variables list keys only, not values
- **Actionable**: every section ends with a "next step suggestion"
- **Decision traceability**: the AI bundle contains full decision history, so a new AI can look up preserved candidates instead of redesigning

---

## F. `/team report` — Work Report Generation

Consolidate project modify logs into a work report suitable for a **2–3 minute briefing**. (Moved here from `/ask report` on 2026-04-17 because reporting is a collaborative deliverable, not a documentation lookup.)

### Triggers

| Usage | Behavior |
|---|---|
| `/team report` | Full report (all modify logs) |
| `/team report weekly` | Weekly report (past 7 days) |
| `/team report YYMMDD YYMMDD` | Specified range |

### Step 1: Determine the scope

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

---

## G. `/team living` — Living Document Maintenance

Maintain a single, continuously updated project-level document that accumulates outcomes from all whiteboard and decision table closures. Acts as the project's authoritative knowledge base for past discussions, decisions, and preserved candidates.

**This subcommand is primarily auto-called** by `/team board` Step 3.3 and `/team decide` Step 6.4. Manual invocation is supported for viewing or regenerating.

### Document Location

`.local/docs/living/PROJECT_JOURNAL.md`

One file per project; entries are append-only (never overwrite existing rows).

### Triggers

| Usage | Behavior |
|---|---|
| `/team living` | Show the living document path and last-update timestamp |
| `/team living view` | Print the full living document |
| `/team living regen` | Rebuild the document from all `CLOSED_*` source files |

### Step 1: Initialize (First-Time Only)

If `.local/docs/living/PROJECT_JOURNAL.md` does not exist, create the directory and initialize the file using the functional-section layout (2026-04-22 revised):

```markdown
# 專案活文件（Project Journal）

> 建立：YYYY-MM-DD　最後更新：YYYY-MM-DD HH:MM　專案：<project-name>

## 目錄

(A linked TOC mirroring the `##` sections below; sections added on demand as new functional areas appear — e.g., OCR Pipeline, Skill 規則, Setup, 部署)

---

<!--
Populate this file by appending full `###` entries under a matching `##` functional section.
Each `###` entry must contain all five elements: 背景／最終決策／變更清單／🔖 保留候選／遺留項, ending with a link back to CLOSED_*.md. See decide Step 6.1 / board Step 3.3 for the template.

Ordering inside each `##` section: newest entry on top (descending date).
-->
```

Functional-section layout replaces the earlier table-based design (決策紀錄 / 討論成果 / 保留候選 tables) because decide Step 6.1 and board Step 3.3 now write **complete summaries** directly into the journal, not one-line pointers. Reading by functional area surfaces related decisions next to each other.

### Step 2: Append from Board Closure

Called internally after `/team board` Step 3.2+3.3. Input: the renamed whiteboard file path.

Actual write is performed by board Step 3.3 itself (write a full `###` entry into the matching `##` functional section, five elements required, back-link to `CLOSED_*`). `/team living` here only validates that the entry was added and refreshes the 最後更新 timestamp.

### Step 3: Append from Decide Closure

Called internally after `/team decide` Step 6.1+6.3. Actual write is performed by decide Step 6.1 itself (full `###` entry with five elements). `/team living` here only validates and refreshes timestamp.

### Step 4: Regen Flow

For `/team living regen` (災後復原 / 大量重整):
1. Back up the current file to `PROJECT_JOURNAL.md.bak`
2. Reset body to the Step 1 initialization template (keep header, clear `##` sections)
3. Scan all `CLOSED_*` files in `.local/docs/whiteboard/` and `.local/docs/decision/`
4. For each, re-derive a five-element `###` entry (background from 背景／context, decisions from checkboxes + 補充說明, changes from git log around the closure commit, preserved candidates from unchecked non-mutex options, leftover from pending notes)
5. Group entries under appropriate `##` functional sections (heuristic: filename prefix, topic keywords)
6. Report: "Rebuilt from N whiteboard sessions, M decisions; backup at PROJECT_JOURNAL.md.bak"

### Design Principles

- **Completeness over brevity**: each `###` entry is self-contained (五要素齊全) — reading the journal alone answers "what was decided and why"
- **Functional sections over chronology**: readers ask "what do we know about OCR pipeline?", not "what happened on 2026-04-22"
- **Append-only**: entries are added, never deleted (permanent historical record); superseded candidates marked `(deprecated)` not removed
- **One file per project**: complete picture of all outcomes in one place
- **Auto-updated on closure**: no manual maintenance needed — board and decide write directly; `/team living` only verifies
- **Linked to source**: every entry back-links to `CLOSED_*` for drill-down into full interactive history

---

Arguments: $ARGUMENTS (the first token is the subcommand, the rest are arguments for that subcommand)
