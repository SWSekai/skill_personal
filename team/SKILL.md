---
name: team
description: "One-stop entry for interactive collaboration: AI TODO handling, live whiteboard, Markdown interactive decision tables, tech notes, handoff documents, and work reports. Subcommand routing: todo / board / decide / note / handoff / report."
model: sonnet
effort: medium
argument-hint: "<todo|board|decide|note|handoff|report> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git *), Bash(ls *), Bash(date *), Bash(mkdir *)
---

# /team — Interactive Collaboration Merged Skill

Integrates six collaboration modes that interact with the user. The first argument determines the subcommand.

## Subcommand Routing

| Subcommand | Purpose | Corresponding Original Skill |
|---|---|---|
| `/team todo [add/list/<n>]` | Process AI TODO list | todo |
| `/team board [topic]` | Live whiteboard (consultation / planning conversations) | whiteboard |
| `/team decide <topic>` | Markdown interactive decision table | md-collab |
| `/team note [topic]` | Structured tech notes | tech-notes |
| `/team handoff` | Handoff document generation | handoff |
| `/team report [scope]` | Generate work reports from modify logs | report (moved from `/ask`) |

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

### Step 3: Closure and Archival

1. Change status to **Completed** or **Paused**
2. Confirm all pending items have an owner or follow-up plan
3. File stays in `.local/docs/`, not under version control
4. Contains reusable experience → evaluate writing it into a guide (same as `/build commit` Step 9)

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

### Step 6: Summary Persistence + Decision File Cleanup (Mandatory, Cannot Be Skipped)

> **This step is mandatory**. After Step 5 implementation completes, the summary + deletion **must be completed in the same reply**.
> Forbidden: replying to the user directly after implementation without writing the summary, leaving the summary to the next reply, waiting for the user to remind before doing it.

**Summary first, delete second** (aligned with CLAUDE.md Rule 17):

#### 6.1 Create Summary (Mandatory)

Write to `.local/docs/summary/YYMMDD_<topic>_summary.md` (permanently retained):

```markdown
# Summary — <Topic>

> **Created**: YYYY-MM-DD
> **Status**: ✅ Executed
> **Commits**: `<hash>` (if any)
> **Original decision file**: `.local/docs/decision/<filename>` (deleted)

---

## Background
(Reason for trigger, 1–3 sentences)

## Final Decisions
| § | Option | Adopted |
|---|---|---|
(One row per decision block)

## Execution Change List
| File | Change |
|---|---|

## 🔖 Preserved Candidates (Not adopted but can be restarted)
(Required only for non-single-path decisions)
- **Candidate X**: <description>
  - Reason not selected: ...
  - Restart timing: ...

## Unresolved Leftover Items
(Write "None" if none)
```

#### 6.2 Non-Single-Path Judgment (Mandatory)

Determine whether each set of decision options is mutually exclusive:
- Picking A precludes B → **single-path** → only record the final choice
- Multiple can coexist → **non-single-path** → retain unselected options in the summary (format as in the template above)
- Candidate cleanup: unvisited for over 6 months or superseded by a new decision → mark as "deprecated", **do not delete**
- When a new conversation has a similar need → first read the preserved candidates in the corresponding section of summary/; restart if possible

#### 6.3 Delete the Decision File (Mandatory)

- **Proactively delete** `.local/docs/decision/<topic>.md`
- The decision file is a one-time artifact; the summary is the persistent record
- If the user explicitly says "keep the decision record" → skip deletion and note it in the reply
- Need to preserve interaction history (not decision results) → use `/team board` instead (`whiteboard/`-type files are not deleted)

#### 6.4 Self-Check (Mandatory)

After Step 6 completes, confirm:
- [ ] `.local/docs/summary/YYMMDD_<topic>_summary.md` has been created and is non-empty
- [ ] Summary includes: background, decision table, change list, preserved candidates (if applicable), leftover items
- [ ] `.local/docs/decision/<topic>.md` has been deleted (or the user explicitly requested retention)
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

Arguments: $ARGUMENTS (the first token is the subcommand, the rest are arguments for that subcommand)
