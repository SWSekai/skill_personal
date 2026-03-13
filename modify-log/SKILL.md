---
name: modify-log
description: Create or update a structured modification log documenting code changes with versioned naming
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git diff*), Bash(git log*), Bash(ls *), Bash(date *)
---

## Modify Log Protocol

Every significant code change should have a corresponding modify log.

### Step 1: Determine filename

- Format: `YYYYMMDD_v[VERSION].md`
- Locate the project's log directory (common: `docs/changelog/`, `logs/`, or configurable)
- Check today's existing logs to determine version number:
  - If none exist → `v1`
  - If `v1` exists → `v2`, etc.

### Step 2: Gather change info

```bash
git diff --stat
git diff --name-only
git diff --numstat   # per-file added/removed line counts
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
- If the same day already has a log for the same topic, increment the version number

Arguments: $ARGUMENTS (topic description — used for filename and content focus)
