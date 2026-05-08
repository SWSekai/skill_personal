---
name: dispatch
description: "Task router that selects the right model tier (per CLAUDE.md Rule 18) and dispatches via the Agent tool so the model swap is real and verifiable. Logs every dispatch to .local/model_dispatch.log."
model: haiku
effort: low
argument-hint: "<task description> [--model opus|sonnet|haiku] [--agent <subagent_type>]"
allowed-tools: Agent, Read, Bash(date *), Bash(mkdir *), Bash(cat *)
---

# /dispatch — Task Router with Model-Tier Selection

Operationalises CLAUDE.md Rule 18 (Skill Model 三層分工原則): pick the right tier (Opus/Sonnet/Haiku) for a free-form task, then run it via the `Agent` tool so a real model swap happens. The main session model cannot be switched mid-conversation; the Agent tool is the only mechanism that produces a verifiable swap.

## Why this Skill Exists

| Mechanism | Effect on running model |
|---|---|
| Skill `model:` frontmatter | **Hint only** — does not change main session model |
| `/model` slash command | Changes main session, but is user-invoked and not task-specific |
| **`Agent` tool with `model:` parameter** | **Real swap** — sub-agent runs in chosen model in isolated context |

`/dispatch` makes the third option ergonomic for ad-hoc tasks and ensures every dispatch is logged for audit.

## Usage

| Form | Behavior |
|---|---|
| `/dispatch <task>` | Auto-pick tier from heuristics |
| `/dispatch <task> --model opus` | Force a specific tier |
| `/dispatch <task> --agent Plan` | Force a specific subagent_type |

---

### Step 1: Parse Arguments

Split arguments into:
- `task` — the free-form task description (everything not flagged)
- `--model <tier>` — optional explicit tier override
- `--agent <type>` — optional explicit subagent_type override

If `task` is empty, ask the user for one and stop.

### Step 2: Select Tier (if not forced)

Apply Rule 18 heuristics in order. First match wins:

| If task contains keyword(s) | Tier |
|---|---|
| `review`, `audit`, `evaluate`, `assess`, `architecture`, `design`, `decide`, `plan`, `propose`, `risk`, `compare options` | **opus** |
| `implement`, `refactor`, `fix`, `add`, `edit`, `modify`, `migrate`, `port`, `wire up`, `integrate`, `build`, `update` | **sonnet** |
| `summarize`, `format`, `template`, `fill in`, `generate log`, `write doc`, `list`, `extract`, `convert` | **haiku** |
| (no match) | **sonnet** (safe default) |

If the task is ambiguous (matches multiple tiers), prefer the higher tier. Briefly state the chosen tier and one-line reason in the reply.

### Step 3: Select subagent_type (if not forced)

Match against the available agent catalogue:

| If task is about... | subagent_type |
|---|---|
| Codebase exploration, finding files, code questions | `Explore` |
| Architecture / implementation planning | `Plan` |
| Claude Code, Anthropic SDK, agent SDK questions | `claude-code-guide` |
| Anything else | `general-purpose` |

### Step 4: Log the Dispatch

Append one line to `.local/model_dispatch.log`:

```
[YYYY-MM-DD HH:MM:SS] model=<tier> agent=<subagent_type> task="<first 80 chars>"
```

Create the directory if missing. The hook `log_agent_dispatch.cjs` ALSO writes a parallel record automatically when any `Agent` tool fires — so this entry plus the hook entry together prove the dispatch happened with the intended parameters (any mismatch reveals a bug).

### Step 5: Dispatch via Agent Tool

Call:

```
Agent({
  subagent_type: <chosen>,
  model: <chosen tier>,
  description: "<3-5 word summary>",
  prompt: "<full task description, self-contained per Agent tool guidance>"
})
```

The prompt sent to the sub-agent must be **self-contained** — restate context, files, constraints. The sub-agent has no view of this conversation.

### Step 6: Return the Result

Forward the agent's reply to the user, prefixed with a one-line dispatch footer:

```
↳ Dispatched to <tier> via <subagent_type> (logged to .local/model_dispatch.log)

<agent result>
```

---

## Verification Workflow

1. Run `/dispatch <task>` — observe the dispatch footer
2. Inspect `.local/model_dispatch.log`:
   ```
   tail -5 .local/model_dispatch.log
   ```
3. Cross-reference with the hook log (`log_agent_dispatch.cjs` writes a `[hook]` prefixed line on every Agent call). Two entries per dispatch = success. One entry only = the Skill ran but didn't dispatch (bug), or another path invoked Agent without /dispatch (also useful info).

## Examples

| Input | Resolved tier · agent |
|---|---|
| `/dispatch review the auth rewrite for race conditions` | opus · general-purpose |
| `/dispatch refactor user_service.py to use new logger` | sonnet · general-purpose |
| `/dispatch summarize this week's modify_log entries into a 5-bullet weekly` | haiku · general-purpose |
| `/dispatch find all callers of deprecated parseRequest()` | sonnet · Explore |
| `/dispatch design a migration plan for splitting the monolith db` | opus · Plan |

## Notes

- The `/dispatch` Skill itself runs at **Haiku** tier — it's pure routing logic, no heavy work
- For Skills that have their own internal multi-tier dispatch (e.g. `/commit-push` Step 1 quality check), don't wrap them in `/dispatch` — they already do the right thing
- For verification of which model is actually executing inside the sub-agent, instruct the sub-agent's prompt to begin its reply with `[model: <self-report>]` — Claude can self-identify

---

## Cross-Skill References

| Direction | Target | Trigger / Purpose |
|---|---|---|
| → Calls | Agent tool | The actual model-switch mechanism — `/dispatch` only chooses tier and prompts |
| ← Called by | None (user-initiated ad-hoc) | — |
| ↔ Shared | `.local/model_dispatch.log` | Audit trail of every dispatch |
| ↔ Shared | `hooks/log_agent_dispatch.cjs` | PreToolUse hook that writes the log entry on every Agent invocation |

**Rename History (this skill only)**: None. Global rename history: see `_bootstrap/RENAME_HISTORY.md`.

---

Arguments: $ARGUMENTS
