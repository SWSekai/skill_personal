---
name: trace-flow
description: Trace a data field or feature's complete flow through the system — from UI to storage to processing — identifying data loss risks
model: opus
effort: high
argument-hint: "[entry-point]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Agent
---

## Data Flow Trace

Trace how a specific field or feature flows through the entire system, end-to-end.

### Step 1: Discover architecture

Before tracing, understand the project's architecture:
- Read `docker-compose.yml`, `package.json`, project README, or equivalent
- Identify layers: frontend → API → services → storage → processing
- Note serialization boundaries (JSON, protobuf, form data, etc.)

### Step 2: Trace through each layer

For the feature or field described in $ARGUMENTS, trace through every layer:

#### Frontend (UI → client-side logic → API call)
- Where is the value entered or displayed? (HTML element, component)
- How is it stored in client state? (React state, Vue ref, plain JS variable)
- How is it serialized for the API call? (JSON body, query param, form data)
- **Risk**: JS `undefined` → stripped by `JSON.stringify`; optional fields may be omitted

#### API Layer (receive → validate → store → forward)
- Which endpoint receives it?
- What validation is applied? (schema, types, constraints)
- Is it persisted to a database? Which table/column?
- Is it forwarded to downstream services? Under what key name?
- **Risk**: Field not in schema → silently dropped; type coercion issues

#### Service Layer (receive → cache → parse → use)
- How is it received from the API layer?
- Is it cached? (Redis, in-memory) How is it serialized?
- How is it parsed/extracted from the payload?
- How is it used at runtime?
- **Risk**: Field not extracted during parsing → lost; cache expiry → stale value

#### Storage Layer (if applicable)
- Database column type and constraints
- Default values at DB level vs application level
- Migration requirements for schema changes

### Step 3: Document each hop

For every step, record:
- **File**: exact path and line number
- **Variable name**: what it's called at this layer (names often change between layers)
- **Transform**: any mapping, renaming, type conversion, or defaulting
- **Default/Fallback**: what happens if the value is missing
- **Data loss risk**: where the value could be silently lost

### Step 4: Output

Summary table:

| Layer | File:Line | Variable | Type | Default | Risk |
|---|---|---|---|---|---|
| Frontend UI | `index.html:42` | `#myInput` | string | `""` | None |
| Frontend JS | `app.js:100` | `config.myField` | number | `30` | `undefined` → stripped |
| API endpoint | `routes/api.py:50` | `request.my_field` | Optional[int] | `None` | Missing → None |
| Cache | `redis_service.py:20` | `rules.myField` | JSON | N/A | Key absent |
| Processing | `processor.py:80` | `parsed["my_field"]` | int | `60` | Fallback mismatch |

**Verdict**: Does the value reliably flow end-to-end? If not, identify exactly where it breaks and suggest fixes.

Arguments: $ARGUMENTS (the field or feature to trace, e.g., "cooldown", "page_size", "auth_token")
