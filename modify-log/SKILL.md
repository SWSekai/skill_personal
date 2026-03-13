---
name: modify-log
description: "MANDATORY before every commit: Create or update a structured modification log documenting code changes. Must be invoked before any git commit operation, including Claude Code's own commit planning."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git diff*), Bash(git log*), Bash(git status*), Bash(ls *), Bash(date *)
---

## Modify Log Protocol

Every significant code change should have a corresponding modify log.
This skill is **auto-triggered** whenever a commit is about to be made — including Claude Code's self-planned commits, `/commit-push`, or any other commit flow.

### Step 1: Determine filename

- Format: `YYMMDD_TopicDescription.md`（6-digit date + descriptive topic name）
- Example: `260313_video_h264_reencode.md`
- Locate the project's log directory (common: `docs/changelog/`, `logs/`, or configurable)
- Check existing logs to avoid duplicates:
  - Same topic exists today → update that file
  - Different topic → create a new file with a distinct name

### Step 2: Gather change info

```bash
git diff --stat
git diff --name-only
```

For each changed file, count added/removed lines:
```bash
git diff --numstat
```

### Step 3: Write the log

```markdown
# [Title — brief description of the change]

## Change Info

- **Date/Time**: YYYY-MM-DD HH:MM
- **Version**: vX
- **Reason**: [Motivation / problem description / requirement source]

## Change Details

| File | Lines affected | Summary |
|------|---------------|---------|
| `path/to/file.py` | +12 / -5 | What was changed and why |
| `path/to/file.js` | +30 / -8 | What was changed and why |

## Technical Notes

(For non-obvious changes: data flow, logic explanation, architecture decisions)

## Impact Scope

- Affected modules / features
- Service restart requirements (if containerized)
- DB migration requirements (if applicable)

## Potential Risks

- Known edge cases or compatibility concerns
- If none: "No known risks"
```

### Rules

- Match the project's primary language (detect from existing docs/commits)
- Include code snippets for non-obvious changes
- Use tables for before/after comparisons
- Use ASCII diagrams for data flow or decision logic
- If the same day already has a log for the same topic, update that file

Arguments: $ARGUMENTS (topic description — used for filename and content focus)
