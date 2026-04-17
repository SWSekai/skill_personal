---
name: clean
description: "Context cleanup entry point: inherits all context-guard functions (summary generation, state tracking, task switch detection, summary recovery). Cleans old summaries before executing /clear. Stop hook auto-reminds when stale summaries detected."
model: sonnet
effort: low
argument-hint: "[check|force]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(rm *), Bash(mkdir *), Bash(git status*), Bash(git log*), Bash(date *)
---

## Context Cleanup Entry Point (inherited from context-guard)

### Capability Boundaries

| Feature | Feasible | Notes |
|---------|:--------:|-------|
| Manual `/clean` | Yes | Available anytime |
| System compression trigger | Yes | Only reliable automatic signal |
| Recover summaries on conversation start | Yes | Chained by `/hello` |
| Stop hook detects stale summaries | Yes | Reminds when previous session summaries exist |
| Measure context usage percentage | No | No API available |
| Auto-count conversation turns | No | No built-in counter |
| Hook directly triggers /clean | No | Hooks cannot execute slash commands |

---

### Step 1: Trigger Condition Check

This skill triggers under the following conditions:

1. **System compression notification** (automatic): Upon receiving `context compressed` or similar system message, proceed to Step 2
2. **Manual invocation** `/clean`: User-initiated
3. **Conversation start** (chained by `/hello`): Check for pending summaries → jump to Step 5

Argument handling:
- `/clean check` → Status detection only. No summary generation, no cleanup, no /clear
- `/clean force` → Skip uncommitted confirmation, execute full flow
- `/clean` (no args) → Full flow

---

### Step 2: Record Current Work State

Create summary in `.local/context_summary/` (create directory if not exists):

**Filename format**: `YYMMDD_HHMM_TopicDescription.md`

```markdown
# Context Summary — [Topic Description]

## Date/Time
YYYY-MM-DD HH:MM

## Current Work in Progress
- [Task description and current progress]

## Completed Work
- [Completed items]

## Uncommitted Changes
[Run git status to list]

## Pending Items
- [Tasks not yet started or needing follow-up]

## Key Decisions & Context
- [Design decisions, user preferences, information to carry forward]

## Service Restart Requirements
[If any, list containers and commands; otherwise "None"]
```

---

### Step 3: Update Topic State File

Write or update `.local/context_summary/current_topic.md`:

```markdown
# Current Work Topic

- **Topic**: [one-line description]
- **Updated**: YYYY-MM-DD HH:MM
- **Related Summary**: [summary filename]
```

This file is used for task switch detection (Step 4).

---

### Step 4: Task Switch Detection (semi-automatic)

**Trigger**: Read `current_topic.md` before processing a new user request and compare:

- If the new request clearly belongs to a **different functional area** (e.g., from "frontend UI changes" to "training service refactor"):
  1. Alert: "Detected task switch ([old topic] → [new topic]), recommend cleaning context."
  2. Confirm whether to commit current changes
  3. Generate summary → suggest `/clean`
  4. Update `current_topic.md` to new topic

- If the new request is an **extension of the same workflow** (e.g., commit followed by container restart question):
  - Do not trigger, only update `current_topic.md`

**Judgment basis**: Based on code impact scope, not surface keywords. Operations within the same service or module are considered the same topic.

**Limitation**: This detection depends on Claude proactively reading the state file — it is not truly automatic.

---

### Step 5: Summary Recovery & Lifecycle (conversation start)

**At conversation start** (chained by `/hello`):
1. Check `.local/context_summary/` for `.md` summary files (excluding `current_topic.md`)
2. Found → Read latest summary, present to user, ask whether to continue
3. Not found → Start normally

**Stale cleanup criteria**:
- All work in summary is completed (committed + pushed) → Delete summary
- `current_topic.md` not updated for 24+ hours → Treat as stale, clean up

---

### Step 6: Commit Confirmation

If `git status` shows uncommitted changes:

1. Execute `/commit-push` directly (let user approve/deny via tool confirmation UI)
2. Approved → Run `/commit-push`; Denied → Continue

If `/clean force` → Skip this step.

---

### Step 7: Clean Old Summaries

Delete all old summaries in `.local/context_summary/` **except the new summary just created in Step 2**:

```bash
# List all summaries (exclude current_topic.md)
ls .local/context_summary/*.md | grep -v current_topic.md

# Delete old summaries (keep only the one created in Step 2)
```

If `/clean check` → Skip this step.
If no old summaries exist → Output "No stale summaries to clean", continue.

---

### Step 8: Execute /clear

After all summaries are saved and old summaries cleaned:

```
Summary saved to: .local/context_summary/YYMMDD_HHMM_Topic.md
Old summaries cleaned (N files removed)
Executing /clear to reset context...
```

Then execute the built-in `/clear` command to clear conversation context.

---

Arguments: $ARGUMENTS (optional: `check` = status only, `force` = skip confirmations)
