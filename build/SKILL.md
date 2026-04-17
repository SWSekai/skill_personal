---
name: build
description: "One-stop entry for the full development flow: requirement analysis → solution design → implementation → testing → quality check → review → deploy. Commit & push is handled by the standalone `/commit-push`. Subcommand routing: flow / plan / impl / test / quality / review / deploy."
model: sonnet
effort: medium
argument-hint: "<flow|plan|impl|test|quality|review|deploy> [args...]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(docker *), Bash(ls *), Bash(date *), Bash(sleep *), Bash(mkdir *), Bash(npm *), Bash(npx *), Bash(pytest *), Bash(python *)
---

# /build — Full Development Flow Skill

Covers the complete development lifecycle from requirement analysis to deployment verification. The first argument selects the subcommand.

**Architecture note**: The commit flow has been split out into `/commit-push` (the primary entry point). `/build` handles development work **before** commit and deployment verification **after** commit.

## Subcommand Routing

### Early development (requirement → implementation → verification)

| Subcommand | Purpose | Model |
|---|---|---|
| `/build all <feature>` | **Full flow chain**: plan → impl → test → review → `/commit-push` → deploy | sonnet |
| `/build plan <feature>` | Requirement analysis + solution design + step breakdown, produces a plan document | **opus** |
| `/build do [plan-ref]` | Implement step-by-step according to the plan, auto-check progress, detect deviations | sonnet |
| `/build test [scope]` | Test verification: auto-run tests + manual checklist + edge cases | sonnet |

### Pre/post commit (quality → review → deploy)

| Subcommand | Purpose | Model |
|---|---|---|
| `/build check [files...]` | Standalone quality audit (callable independently; also embedded in `/commit-push` Step 1) | **opus** |
| `/build review` | Final manual confirmation checklist before commit (strongly recommended for large changes) | sonnet |
| `/build deploy [--plan\|--run] [services...]` | Merged restart assessment + execution. By default lists the plan first, then executes | sonnet |

Without arguments → ask the user to specify a subcommand.

**Commit & push**: use `/commit-push` (a standalone Skill that includes quality check / change log / README / commit / push / deploy --plan / context cleanup).

---

## F. `/build all` — Full Flow Chain

**Automatically chains** the six stages plan → impl → test → review → `/commit-push` → deploy, without needing to manually invoke the next step in between.

### Flow

```
/build all <feature description>
    │
    ├─ Step 1: /build plan (Opus solution design)
    │   └─ User confirms the plan via AskUserQuestion
    │       ├─ Confirm → enter impl
    │       └─ Modify → adjust the plan and re-confirm
    │
    ├─ Step 2: /build do (Sonnet step-by-step implementation)
    │   └─ All steps completed
    │
    ├─ Step 3: /build test (test verification)
    │   └─ All passing?
    │       ├─ Yes → enter review
    │       └─ No → list failures, go back to impl to fix
    │
    ├─ Step 4: /build review (final manual checklist confirmation)
    │   └─ User checks off items → enter commit-push
    │
    ├─ Step 5: /commit-push (quality → log → commit → push)
    │   └─ Done
    │
    └─ Step 6: /build deploy (restart assessment + execution)
        └─ Done
```

### Interruption and resumption

- If interrupted at any stage, the plan document is preserved at `.local/docs/plan/`
- Resume with: `/build do <plan-file>` to continue from the last progress
- Checkboxes in the plan document record completion state, so unfinished steps can be identified after interruption

---

## G. `/build plan` — Requirement Analysis and Solution Design (Opus)

When receiving a feature request, **design the complete solution first and implement only after confirmation** (aligned with CLAUDE.md core rules).

This subcommand falls under "assessment / planning / architectural decision" attributes; it is recommended to invoke an Opus subtask via the Agent tool (aligned with CLAUDE.md rule 18).

### Step 1: Requirement understanding

1. **Parse the user description**: extract core feature requirements, acceptance criteria, constraints
2. **Clarify ambiguities**: use AskUserQuestion to follow up on unclear requirements
   - Only ask questions that truly affect the solution direction
   - Do not ask about details that can be derived from the code; state the assumption directly in the plan

### Step 2: Current state scan

1. **Related code**: use Grep / Glob to find existing implementations related to the requirement
2. **Architecture awareness**: read compose, package.json, directory structure to understand the system layering
3. **DB schema**: if data is involved, scan models / migrations / collection definitions
4. **Related APIs**: find the endpoints and frontend call sites that will be affected

### Step 3: Impact scope assessment

| Dimension | Items to check |
|---|---|
| File impact | List all files to be added / modified |
| Service impact | Which containers / services will be touched |
| DB impact | Whether to add collection / table / column / index |
| API impact | Which endpoints are added or modified; request / response structure |
| Frontend impact | Which pages / components need adjustment |
| Backward compatibility | Whether existing features will be affected |

### Step 4: Solution design

**If multiple approaches exist**: list alternative solutions with a pros/cons comparison table

```markdown
| Solution | Description | Pros | Cons |
|---|---|---|---|
| A | ... | ... | ... |
| B | ... | ... | ... |
```

The **final solution** must include:
- Technology choices and rationale
- Data flow design (if cross-service is involved)
- Error handling strategy
- Performance considerations (if large data volumes are involved)

### Step 5: Step breakdown

Decompose the solution into a **step-by-step implementable list**, each step mapped to a concrete code change:

```markdown
## Implementation steps

- [ ] §1 Create DB model / schema
  - File: `backend/models/xxx.py`
  - Add: XxxModel class, field definitions

- [ ] §2 Create API endpoint
  - File: `backend/routers/xxx.py`
  - Add: GET /api/xxx, POST /api/xxx
  - Depends on: §1

- [ ] §3 Frontend page
  - File: `frontend/src/pages/xxx.vue`
  - Add: list page + form
  - Depends on: §2
```

Each step must specify:
- Target file and behavior (add / modify)
- Dependencies (cross-reference by § number)
- Estimated impact line count (rough is fine)

### Step 6: Plan confirmation

Use **AskUserQuestion** to present the plan to the user:
- First option: `Start execution (Recommended)`
- Second option: `I want to adjust` (enters the modification flow)
- Third option: `Switch solution` (if an alternative exists)

After confirmation:
1. Write the plan to `.local/docs/plan/YYMMDD_<feature>.md`
2. If inside `/build all` → automatically proceed to `/build do`
3. If called standalone → tell the user "Plan saved; you can start implementation with `/build do`"

---

## H. `/build do` — Implement According to the Plan (Sonnet)

### Usage

| Usage | Behavior |
|---|---|
| `/build do` | Read the most recent plan document, continue from the unfinished steps |
| `/build do <plan-file>` | Specify a plan document |
| Chained from `/build all` | Automatically carries in the just-confirmed plan |

### Step 1: Load the plan

1. Read the plan document (`.local/docs/plan/YYMMDD_<feature>.md`)
2. Parse the implementation step list and checkbox states
3. Find the first unchecked (`- [ ]`) step as the starting point
4. If all are checked → report that implementation is complete and suggest `/build test`

### Step 2: Execute step by step

For each step:

1. **Announce the step being executed** (one sentence to inform the user)
2. **Read related files**: understand existing code first
3. **Perform the implementation**: add or modify code per the plan description
4. **Deviation detection**:
   - If the implementation reveals that the plan is wrong or incomplete → pause and explain the reason for deviation to the user
   - After the user confirms the adjustment direction, **update the plan document** before continuing
5. **Check off completion**: change `- [ ]` to `- [x]` in the plan document and append a timestamp

```markdown
- [x] §1 Create DB model / schema ✓ 2026-04-10 14:30
```

6. **Derived tasks**: if additional work is discovered during implementation:
   - Within the scope of this feature → add a new step at the end of the plan document
   - Out of scope → add to `.local/collab/TODO.md` (tagged `derived from: <feature>`)

### Step 3: Implementation complete

After all steps are checked off:

1. Update the plan document status to `## Status: Implementation complete`
2. List the implementation summary (which files were modified, what was added)
3. If inside `/build all` → automatically proceed to `/build test`
4. If called standalone → suggest "Implementation complete; `/build test` is recommended for verification"

---

## I. `/build test` — Test Verification (Sonnet)

### Usage

| Usage | Behavior |
|---|---|
| `/build test` | Auto-detect the project's test framework, run all + manual checklist |
| `/build test <scope>` | Run only tests within the specified scope |
| Chained from `/build all` | Executed automatically |

### Step 1: Detect the test framework

Scan the project structure to determine available test tooling:

| Detection condition | Test framework | Run command |
|---|---|---|
| `pytest.ini` / `pyproject.toml[tool.pytest]` / `tests/` | pytest | `pytest --tb=short` |
| `jest.config.*` / `package.json[jest]` | Jest | `npx jest` |
| `vitest.config.*` | Vitest | `npx vitest run` |
| `cypress/` / `playwright/` | E2E | List but do not auto-run |
| No test framework | — | Skip to Step 3 manual checklist |

### Step 2: Run automated tests

```bash
# Choose based on detection result
pytest --tb=short -q 2>&1 | tail -20
# or
npx jest --ci 2>&1 | tail -30
```

**Result handling**:
- All pass → proceed to Step 3
- Any failure → list failing test cases and error messages, and analyze the cause:
  - **Implementation bug** → mark files and line numbers that need fixing
  - **Test itself is outdated** → explain the test needs updating
  - **Environment issue** → explain required environment configuration

### Step 3: Manual verification checklist

Based on the plan document (if it exists) or the current change, generate a checklist of items that need manual verification:

```markdown
## Manual verification checklist

### Feature verification
- [ ] Core functionality works correctly (describe concrete steps)
- [ ] Related features are not affected

### Edge cases
- [ ] Empty / null input
- [ ] Overlong strings / very large numbers
- [ ] Concurrent operations (multiple users triggering simultaneously)
- [ ] Network outage / external service unavailable

### UI verification (if frontend changes exist)
- [ ] Different resolutions / browsers
- [ ] Loading state and error notifications

### Security
- [ ] Access control (unauthorized users cannot access)
- [ ] Input validation (no injection risk)
```

**Only list items relevant to this change**; do not list unrelated boilerplate.

### Step 4: Test report

```markdown
## Test results

| Category | Result | Note |
|---|:---:|---|
| Automated tests | ✓ 32 passed | pytest |
| Manual checklist | ◯ pending | 5 items need manual confirmation |
| Edge cases | ✓ confirmed | No risk |
```

**Flow decision**:
- All automated tests passing + no High risk → may enter review
- Any failure → if inside `/build all`: go back to impl to fix → retest
- Manual checklist items pending → prompt the user to complete them before entering review

---

## B. `/build check` — Quality Audit (Opus)

Standalone entry point for in-depth quality audit. **Recommended to invoke an Opus subtask via the Agent tool** (aligned with CLAUDE.md rule 18; quality analysis is an assessment / thinking attribute).

`/commit-push` Step 1 embeds similar logic; this standalone entry serves the scenario "I don't want to run the full commit flow, just a quality scan."

### 1. Scan items

For each changed file, check:
- **Dead code**: unused imports, unreachable branches, commented-out code
- **Redundancy**: duplicated logic across files, copy-paste that should be abstracted
- **Hard-coding**: magic values that should live in config/constants
- **Error handling**: try/catch at system boundaries (API, external calls, file IO)
- **Type consistency**: type mismatches across layers
- **Serialization risks**: fields that may be lost during JSON/protobuf/form processing
- **Security**: SQL injection, XSS, command injection, sensitive information leakage, OWASP Top 10

### 2. Architecture consistency

Read 3–5 existing files from the same directory to understand conventions (naming, error handling, log style, response format); list deviations with existing examples.

### 3. Impact assessment

| Dimension | Question |
|---|---|
| Upstream | Who calls this function/endpoint? Will it break? |
| Downstream | Who does this function call? Is the contract still valid? |
| State | Does it touch DB schema, cache key, file path, or env var? |
| Concurrency | Could race conditions occur under multi-user / multi-worker scenarios? |
| Backward compat | Are existing DB records, saved configs, cached values still usable? |
| API contract | If request/response shape changed, are all clients updated? |

### 4. Risk report

| Severity | File | Description | Mitigation |
|---|---|---|---|
| High / Med / Low | ... | ... | ... |

- **High**: may cause data loss, crashes, or security vulnerabilities
- **Medium**: may cause incorrect behavior or performance degradation
- **Low**: code smell or minor inconsistency

When there is no risk, output explicitly: "Quality check passed, no risks"

### 5. Skill update detection

If this change introduces new conventions, patterns, or workflow requirements:
- **Directly execute the Edit on the corresponding SKILL.md**, letting the Tool Confirmation UI handle approve / deny (aligned with CLAUDE.md rule 15)
- **Do not** ask in text "Should I update the Skill definition?"

### 5b. Skill integrity check (if Skill files are modified)

If this change touches any SKILL.md / README.md / newly created Skill folders, verify each item:

1. **Every skill folder** contains both `SKILL.md` and `README.md`
2. **Three-section sync in Skills README**:
   - The command overview table in `.claude/skills/README.md` is updated
   - The detailed description sections are updated
   - The directory structure tree is updated
3. **Universal vs. project-specific decision tree**:
   - Universal improvement (not tied to project details) → sync to `sekai-workflow/`, **strip all project-specific hard-coded values**
   - Project-specific fix → keep only in `.claude/skills/`, **do not sync**
4. **Universal skills README** is updated
5. The **"Available Skills" list in CLAUDE.md** is updated
6. **Explicit declaration**: Skill changes flow through the `sekai-workflow` standalone remote repository; they **do not enter the project's git**

Any item that fails → halt the flow and ask the user to complete it.

### 5c. Post-implementation data flow re-read

After implementation is complete and before commit, **re-read** the modified code and walk through it layer by layer:

| Check item | Result | Note |
|---|:---:|---|
| Data flow integrity | ✓/✗ | |
| Cross-layer type consistency | ✓/✗ | |
| Edge case handling | ✓/✗ | |
| Untouched logic is unaffected | ✓/✗ | |

Any ✗ must be fixed first before entering the commit flow.

---

## R. `/build review` — Final Manual Confirmation Before Commit (Sonnet)

Used as a **final checklist gate before a large change**. Difference from `/build check`:

| Aspect | `/build check` | `/build review` |
|---|---|---|
| Purpose | In-depth code quality scan | Architecture / rule-layer manual confirmation |
| Model | Opus | Sonnet |
| Output | Risk report | Checklist to confirm |
| Blocking? | High risks block | Only lists items, does not block |
| When to use | Should run on every commit | When modifying CLAUDE.md / SKILL.md / architecture files |

### Step 1: Scan changed files

```bash
git status --short
git diff --stat
```

Identify **architecture-layer changes**:
- `CLAUDE.md` — project rules
- `*/SKILL.md`, `*/README.md` — Skill definitions
- Root-level config (`docker-compose.yml`, `package.json`, `pyproject.toml`)
- Database schema / migrations

### Step 2: Generate a manual confirmation checklist

Based on the scan results, list **items that may need syncing for this change but have not been handled yet**:

```markdown
## Pre-commit manual confirmation checklist

### Rule-layer sync (when modifying CLAUDE.md / SKILL.md)
- [ ] New rules have been written to Memory (aligned with CLAUDE.md rule 9 three-way sync)
- [ ] The corresponding SKILL.md is updated in sync
- [ ] `.claude/skills/` and `sekai-workflow/` are synced bidirectionally
- [ ] manifest.json is updated
- [ ] The Available Skills list (after CLAUDE.md rule 18) is updated

### Architecture-layer sync (when modifying config / schema)
- [ ] docker-compose changes require updating deployment docs
- [ ] DB schema changes have corresponding migrations
- [ ] New environment variables have matching entries in .env.example

### Documentation-layer sync
- [ ] READMEs for affected directories are updated
- [ ] For new features → there is a corresponding .local/docs/guide/<topic>.md
```

### Step 3: Interactive confirmation

Ask the user about each item (via AskUserQuestion or by listing items for reply). For unfinished items → go back to the corresponding Skill to complete them before entering commit-push.

**This subcommand does not block commit** — it only serves as a reminder. The user may choose "Confirm all" to skip directly.

---

## D. `/build deploy` — Deployment Assessment and Execution (merges legacy restart + eval)

**Unified entry**, behavior determined by flag:

| Invocation | Behavior |
|---|---|
| `/build deploy` | **Default**: eval first to list the plan → wait for confirmation → execute restart |
| `/build deploy --plan` | Eval only, no execution (equivalent to the legacy `/build eval`) |
| `/build deploy --run` | Skip eval and execute directly (equivalent to the legacy `/build restart`) |
| `/build deploy svc1 svc2` | Specify services |
| `/build deploy --run all` | All containers |

### Step 1: Find changed files

```bash
git diff --name-only HEAD~1     # default
git diff --name-only $RANGE      # if $ARGUMENTS is a commit range
```

### Step 2: Read compose topology

```bash
cat docker-compose.yml 2>/dev/null || cat compose.yml 2>/dev/null
```

For each service, determine: volume mount paths / baked-in paths / auto-reload capability / static files.

### Step 3: Classification (Eval stage)

| Mount type | Auto-reload | Action |
|---|---|---|
| Volume mount | yes (`--reload`) | No action needed |
| Volume mount | no | `docker compose restart <svc>` |
| Baked image | N/A | `build + up -d` |
| Static files (web server) | N/A | Browser refresh |
| DB init script | N/A | Manual migration |
| Dockerfile | N/A | rebuild |
| compose file itself | N/A | `docker compose up -d` |

### Step 4: Output the plan

1. Mapping table: changed files → services → actions
2. Deduplicated command list in execution order
3. Side-effect warnings (downtime, connection drops, job interruption)
4. If DB init scripts changed and the DB already exists → list migrations that must be run manually

### Step 5: Pre-flight (Run stage)

```bash
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Service}}"
```

- **Background task check** (worker / queue services): detect active tasks in Celery / Sidekiq / Bull, etc.; warn if any exist
- **Streaming service check** (WebSocket / RTSP / SSE): warn that connections will be interrupted
- **Mount type determination**: volume mount → restart; image baked → build + up

### Step 6: Execute

```bash
# Volume mount
docker compose restart <svc>

# Image baked
docker compose build <svc1> <svc2>
docker compose up -d <svc1> <svc2>
```

After listing the targets, **execute directly** without sending a confirmation message (let the tool permission UI handle it, aligned with CLAUDE.md rule 15).

### Step 7: Health check

```bash
sleep 8
docker compose ps | grep -E "<services>"
```

Expect `Up X seconds (healthy)`; if `Restarting` / `Exited` → proceed to Step 8.

### Step 8: Log scan

```bash
docker compose logs --tail=30 <service>
```

| Keyword | Severity |
|---|---|
| `Error` / `ERROR` | HIGH |
| `ImportError` / `ModuleNotFoundError` / `Cannot find module` | HIGH |
| `ConnectionRefusedError` | MEDIUM |
| `WARNING` | LOW |
| `Application startup complete` / `Listening on` / `ready` | OK |

### Step 9: Auto-repair

| Symptom | Auto-repair | Fallback |
|---|---|---|
| ImportError / Module not found | `docker compose build --no-cache <svc>` | Pin version |
| ConnectionRefused | `docker compose up -d --wait <dep>` → restart | Check dep log |
| Port conflict | `docker compose down <svc>` → `up -d` | Find PID and kill |
| DB migration error | Report required DDL | Execute manually |
| Cannot auto-repair | Full log summary + root cause + manual repair steps | — |

### Step 10: Final verification

- API health: `curl http://localhost:<port>/health` or `/docs`
- Worker connectivity: `celery -A <app> inspect ping`

Output:

```
| Service | Action | Status | Duration |
|---|---|---|---|
```

### Non-containerized projects

Detect PM2 / systemd / supervisor / nodemon / watchdog / air, and provide the corresponding restart command.

---

## Model Usage Recommendations per Subcommand (aligned with CLAUDE.md rule 18)

| Subcommand | Recommended model | Reason |
|---|---|---|
| flow | sonnet | Chain meta-command, main body is Sonnet execution |
| **plan** | **opus** | Requirement analysis / solution design / architectural decision (thinking attribute) |
| impl | sonnet | Step-by-step execution (execution attribute) |
| test | sonnet | Multi-step execution + checks |
| **quality** | **opus** | In-depth quality audit / architecture assessment (thinking attribute) |
| review | sonnet | Listing checklists / interactive confirmation |
| deploy | sonnet | Container operation execution |

The Skill body uses `model: sonnet`. Subcommands that need Opus in-depth analysis (plan / quality) are recommended to invoke Opus subtasks via the **Agent tool**, without changing the Skill body's model setting.

**Three-tier separation principle** (CLAUDE.md rule 18):
- **Opus**: assessment, planning, architectural decisions, in-depth quality analysis
- **Sonnet**: multi-step execution, file read/write, medium-low complexity tasks
- **Haiku**: structured text writing, template filling, log generation

Arguments: $ARGUMENTS (the first token is the subcommand; the rest are arguments for that subcommand)
