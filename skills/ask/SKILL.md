---
name: ask
description: "End-to-end data flow tracing for the current project. Layer-by-layer walkthrough (UI → API → service → storage) with data-loss risk annotations."
model: opus
effort: medium
argument-hint: "<field-or-feature>"
allowed-tools: Read, Glob, Grep, Agent, Bash(ls *), Bash(find *), Bash(git log*), Bash(git diff*)
---

# /ask — Data-Flow Tracing Skill

> **2026-05-06 scope reduction**: the legacy `info` subcommand and its `ask_info_router.cjs` UserPromptSubmit hook were removed. System-info queries now go through plain conversation with Claude (no skill ceremony). Project-specific knowledge writes go to `/team note` (project-local) or `/kb add` (cross-project). Only `trace` remains because it carries structured methodology that plain Q&A does not replicate.

## Usage

```
/ask <field-or-feature>
```

The argument is the field name or feature description to trace end-to-end.

---

## Step 1: Understand the Architecture

Before tracing, familiarize yourself with the project architecture:
- Read `docker-compose.yml`, `package.json`, root README, or equivalent files
- Identify the layers: frontend → API → services → storage → processing
- Mark serialization boundaries (JSON, protobuf, form data, etc.)

---

## Step 2: Trace Layer by Layer

For the field/feature in `$ARGUMENTS`, walk through every layer:

### Frontend (UI → client-side logic → API call)
- Where is the value entered or displayed? (HTML element, component)
- How is it stored in client-side state? (React state, Vue ref, JS variable)
- How is it serialized for the API call? (JSON body, query param, form data)
- **Risk**: JS `undefined` is stripped by `JSON.stringify`; optional fields may be omitted

### API layer (receive → validate → store → forward)
- Which endpoint receives it?
- What validation is applied? (schema, type, constraint)
- Is it written to the DB? Which table/column?
- Is it forwarded to downstream services? Under what key name?
- **Risk**: Fields not in schema → silently dropped; type conversion issues

### Service layer (receive → cache → parse → use)
- How is it received from the API layer?
- Is it cached? (Redis, in-memory) How is it serialized?
- How is it parsed/extracted from the payload?
- How is it used at runtime?
- **Risk**: Not extracted during parsing → lost; cache expiration → stale value

### Storage layer (if applicable)
- DB column type and constraints
- DB-level vs application-level defaults
- Migration requirements for schema changes

---

## Step 3: Record Each Hop

- **File**: Exact path and line number
- **Variable name**: What it's called at this layer (names often change across layers)
- **Transformation**: mapping, rename, type conversion, default value
- **Default/Fallback**: What happens when the value is missing
- **Data loss risk**: Where silent loss may occur

---

## Step 4: Output

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
| ← Called by | None | User-initiated only (auto-routing hook removed 2026-05-06) |
| ↔ Shared | None | — |

**Rename History (this skill only, ≤ 90 days)**:
- 2026-04-24: `/ask report` subcommand migrated to `/team report --daily`
- 2026-05-06: `/ask info` subcommand + `ask_info_router.cjs` hook removed (Plan A — `info` was redundant with plain Q&A; project knowledge writes go to `/team note` or `/kb add`)

Global rename history: see `_bootstrap/RENAME_HISTORY.md`.

---

Arguments: $ARGUMENTS (the field name or feature description to trace)
