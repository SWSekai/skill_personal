---
name: sys-info
description: "Auto-triggered when user asks about system architecture, features, data flow, configuration, deployment, or how things work. Guides user to existing docs or creates/expands documentation."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(find *), Agent
---

## System Information & Documentation Management

When the user asks a question about how the system works, this skill manages the answer **and** the documentation lifecycle.

### Step 1: Search existing documentation

Scan all documentation sources for relevant content:

```
.local/docs/      ← Primary knowledge base (managed by this skill)
docs/                    ← Official project docs
**/README.md             ← Directory-level READMEs
```

Created automatically by `setup.bat`. All local documentation goes here.

### Step 2: Evaluate & respond

Based on search results, follow **one** of three paths:

#### Path A — Documentation already covers it

1. Guide the user to the **specific sections** in the file:
   ```
   Relevant doc: `docs/event_recording.md`

   See these sections:
   - **Section 2: Recording trigger flow** — explains the full data flow
   - **Section 3: MinIO upload** — explains storage and URL generation
   ```
2. Provide a brief summary to aid understanding
3. No file modifications needed

#### Path B — Documentation exists but is incomplete

1. Answer the user's question first
2. Evaluate missing information and expand the **existing file** at the appropriate location
3. Inform the user of the update

#### Path C — No relevant documentation

1. Answer the user's question
2. Organize the answer into a structured document, save to `.local/docs/[topic_description].md`
3. Inform the user of the new file location

### Step 3: Redundancy check

After adding or updating a doc, scan the docs directory:

1. Check for:
   - **Duplicate topics**: Two files describing the same thing → merge into the more complete one
   - **Overlapping content**: Sections repeated across files → keep in the best location, cross-reference elsewhere
   - **Outdated info**: Descriptions that don't match current code → flag or update
2. If redundancy found, inform user and execute merge

### Document format

```markdown
# [Topic Title]

> Last updated: YYYY-MM-DD

## 1. Overview

(One-paragraph summary)

## 2. Details

(Sections organized by subtopic)

## 3. Related Documents

- `docs/xxx.md` — description
- `path/to/README.md` — description
```

### Rules

- Match the project's primary language
- Filename: `[topic_description].md` — concise and descriptive
- Do not copy large code blocks into docs — use file path + line number references
- Prefer expanding existing files over creating many small ones

Arguments: $ARGUMENTS (user's question about the system)
