---
name: modify-log
description: "Create or update a structured local modification log documenting code changes. Invoked after commit — logs are LOCAL ONLY, never committed to project git."
model: haiku
effort: low
argument-hint: "[commit-hash]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git diff*), Bash(git log*), Bash(git status*), Bash(ls *), Bash(date *)
---

## Modify Log Protocol

Every significant code change should have a corresponding modify log.
This skill is **auto-triggered** after a commit is made. Logs are created **after commit** so the commit hash is directly available.

**Important: Modify logs are stored locally only — they are NOT added to any git version control.**

### Step 1: Determine filename

- Format: `YYMMDD_TopicDescription.md`（6-digit date + descriptive topic name）
- Example: `260313_video_h264_reencode.md`
- Log directory: `.local/modify_logs/` (created by `setup.bat`)
- Check existing logs to avoid duplicates:
  - Same topic exists today → update that file
  - Different topic → create a new file with a distinct name

### Step 2: Gather change info

From the completed commit:

```bash
git log --oneline -1                    # get commit hash
git diff --stat HEAD~1                  # change statistics
git diff --name-only HEAD~1             # changed files
git diff --numstat HEAD~1               # per-file added/removed lines
```

### Step 3: Write the log

```markdown
# [Title — brief description of the change]

## Change Info

- **Date/Time**: YYYY-MM-DD HH:MM
- **Version**: `<git-short-hash>` (e.g. `9fe154c`)
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
- **Logs are local only — never add them to git version control**

Arguments: $ARGUMENTS (topic description — used for filename and content focus)
