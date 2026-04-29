---
name: ask
description: "One-stop entry for system documentation and data-flow tracing: system information queries, end-to-end data flow tracing. Subcommand routing: info / trace. (Work reports are handled by /team report.)"
model: opus
effort: medium
argument-hint: "<info|trace> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(ls *), Bash(find *), Bash(git log*), Bash(git diff*), Bash(date *)
---

# /ask — Merged Skill for System Documentation and Data-Flow Tracing

Integrates two responsibilities: sys-info and trace-flow. The first argument determines the subcommand. (Work report generation has been moved to `/team report`.)

## Subcommand Routing

| Subcommand | Purpose | Original Skill |
|---|---|---|
| `/ask info [topic]` | System information queries and documentation management | sys-info |
| `/ask trace <field>` | End-to-end data flow tracing | trace-flow |

When no argument is given, ask the user to specify a subcommand.

---

## A. `/ask info` — System Information Queries and Documentation Management

When users ask how the system works, this subcommand manages both the "answer" and the "document lifecycle".

### Step 1: Search existing documentation

Scan all documentation sources:

```
.local/docs/knowledge/      ← Primary knowledge base (managed by this subcommand)
docs/             ← Official project documentation
**/README.md      ← READMEs in each directory
```

### Step 2: Take one of three paths based on results

#### Path A — Documentation already covers it

Guide the user to **specific sections**:

```
Related document: `docs/event_recording.md`

See these sections:
- Section 2: Recording trigger flow — explains the complete data flow
- Section 3: MinIO upload — explains storage and URL generation
```

Include a short summary to aid understanding. **Do not modify files.**

#### Path B — Documentation exists but is incomplete

1. Answer the question first
2. Assess missing information and **extend the existing file** at an appropriate location
3. Inform the user of the update

#### Path C — No relevant documentation

1. Answer the question first
2. Organize into a structured document and save to `.local/docs/knowledge/[topic_description].md`
3. Inform the user of the new file's location

### Step 3: Redundancy check

After adding or updating documentation, scan the entire docs directory:

- **Duplicate topics**: Two files describing the same thing → merge into the more complete one
- **Overlapping content**: Sections repeated across files → keep in the best location, use cross-references elsewhere
- **Outdated information**: Descriptions that don't match current code → annotate or update

If redundancy is found → inform the user and perform the merge.

### Document format

```markdown
# [Topic Title]

> Last updated: YYYY-MM-DD

## 1. Overview

(One-paragraph summary)

## 2. Details

(Split by subtopics)

## 3. Related Documents

- `docs/xxx.md` — description
- `path/to/README.md` — description
```

### Rules

- Align with project language (follow project conventions, e.g., Traditional Chinese for Taiwan)
- Filename: `[topic_description].md`, concise and descriptive
- Do not copy large code blocks into documentation → reference with `file_path:line_number`
- Prefer extending existing files to avoid proliferation of small files

---

## B. `/ask trace` — End-to-End Data Flow Tracing

Trace the complete flow of a specified field or feature through the system and identify data loss risks.

### Step 1: Understand the architecture

Before tracing, familiarize yourself with the project architecture:
- Read `docker-compose.yml`, `package.json`, root README, or equivalent files
- Identify the layers: frontend → API → services → storage → processing
- Mark serialization boundaries (JSON, protobuf, form data, etc.)

### Step 2: Trace layer by layer

For the field/feature described in `$ARGUMENTS`, walk through every layer:

#### Frontend (UI → client-side logic → API call)
- Where is the value entered or displayed? (HTML element, component)
- How is it stored in client-side state? (React state, Vue ref, JS variable)
- How is it serialized for the API call? (JSON body, query param, form data)
- **Risk**: JS `undefined` is stripped by `JSON.stringify`; optional fields may be omitted

#### API layer (receive → validate → store → forward)
- Which endpoint receives it?
- What validation is applied? (schema, type, constraint)
- Is it written to the DB? Which table/column?
- Is it forwarded to downstream services? Under what key name?
- **Risk**: Fields not in schema → silently dropped; type conversion issues

#### Service layer (receive → cache → parse → use)
- How is it received from the API layer?
- Is it cached? (Redis, in-memory) How is it serialized?
- How is it parsed/extracted from the payload?
- How is it used at runtime?
- **Risk**: Not extracted during parsing → lost; cache expiration → stale value

#### Storage layer (if applicable)
- DB column type and constraints
- DB-level vs application-level defaults
- Migration requirements for schema changes

### Step 3: Record each hop

- **File**: Exact path and line number
- **Variable name**: What it's called at this layer (names often change across layers)
- **Transformation**: mapping, rename, type conversion, default value
- **Default/Fallback**: What happens when the value is missing
- **Data loss risk**: Where silent loss may occur

### Step 4: Output

| Layer | File:Line | Variable | Type | Default | Risk |
|---|---|---|---|---|---|
| Frontend UI | `index.html:42` | `#myInput` | string | `""` | None |
| Frontend JS | `app.js:100` | `config.myField` | number | `30` | `undefined` stripped |
| API endpoint | `routes/api.py:50` | `request.my_field` | Optional[int] | `None` | Missing → None |
| Cache | `redis_service.py:20` | `rules.myField` | JSON | N/A | Key missing |
| Processing | `processor.py:80` | `parsed["my_field"]` | int | `60` | Inconsistent fallback |

**Verdict**: Can the value be reliably propagated end-to-end? If not, pinpoint where it breaks and suggest a fix.

---

## Cross-Skill References

| Direction | Target | Trigger / Purpose |
|---|---|---|
| → Calls | None | Read-only investigation skill — no outbound calls |
| ← Called by | `hooks/ask_info_router.cjs` | UserPromptSubmit hook auto-routes system-info questions to `/ask info` |
| ↔ Shared | None | — |

**Rename History (this skill only)**: `/ask report` subcommand migrated to `/team report --daily` on 2026-04-24. Global rename history: see `_bootstrap/RENAME_HISTORY.md`.

---

Arguments: $ARGUMENTS (the first token is the subcommand; the rest are arguments for that subcommand)
