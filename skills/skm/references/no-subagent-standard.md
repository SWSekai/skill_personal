# --no-subagent Flag — Cross-Skill Standard (Reference)

> Migrated from CLAUDE.md Rule 26 (2026-05-15) per CLOSED_260515_todo_root_cause_and_claudemd_slim_decision.md §2.3.a.
> CLAUDE.md keeps: definition + trigger timing + exception list + violation note. This file holds: applicable-skill table + behavioral spec + implementation template.

---

## 1. Applicable Skills

| Skill | Status | Affected Subcommands / Notes |
|---|---|---|
| `/commit-push` | ✓ Mandatory (2026-05-07) | Step 1 (Opus quality), Step 5 (Haiku modify log) |
| `/build` | ✓ Mandatory (2026-05-08) | `plan` (Opus), `check` (Opus), `all` chain inheritance |
| `/team` | ✓ Mandatory (2026-05-08) | `report --daily` (Haiku), `handoff` (Opus), decide/board closure summary (Opus) |
| `/skm` | ✓ Mandatory (2026-05-08) | Occasional Agent calls (mostly safety guards) |
| `/hello` | ✓ Declarative no-op (2026-05-13) | No Agent dispatch; flag accepted for consistency |
| `/clean` | ✓ Declarative no-op (2026-05-13) | No Agent dispatch; combinable with `check` / `force` |
| `/ask` | ✓ Declarative no-op (2026-05-13) | No dispatch currently; `allowed-tools` includes `Agent` for future |
| `/kb` | ✓ Declarative no-op (2026-05-13) | No Agent dispatch; add/search/extract all run in main session |
| `/memo` | ✓ Declarative no-op (2026-05-13) | No Agent dispatch; mostly auto-triggered |
| `/dispatch` | ✗ Exception | Itself the dispatch mechanism; flag not applicable |

---

## 2. Behavioral Specification

1. **Flag detection**: `$ARGUMENTS` contains `--no-subagent` → all `Agent(...)` calls within the skill become inline main-session execution
2. **No model switching**: main session model stays fixed regardless of what the statusline shows (Opus / Sonnet / Haiku)
3. **Step logic unchanged**: only the sub-agent spawning is bypassed; checklists, output formats, and quality bars remain identical
4. **Chain inheritance**: `/build all --no-subagent` automatically passes the flag to the chained `/commit-push`
5. **Composable**: usable with other flags — `--meta --no-subagent`, `--audit --no-subagent`, etc.

---

## 3. Trigger Timing

- **Explicit skill invocation (highest priority, 2026-05-13)**: when the user types `/<skill>` or `/<skill> <subcommand>`, Claude **auto-prefixes `--no-subagent` by default**. Exceptions: when the user explicitly states they want the full sub-agent flow. Claude's own chained calls (board closure auto-trigger of `/team report --daily`, `/commit-push` Step 11 chain, etc.) do NOT auto-add this; they fall back to the conditions below.
- Main session is Opus 4.7 1M context (model id suffix `[1m]`) and `/extra-usage` is not enabled
- A previous run aborted with `API Error: Extra usage is required for 1M context`
- User wants a single-transcript audit trail (debugging, verification, compliance)

---

## 4. Implementation Template

Canonical version: see `commit-push/SKILL.md` § `--no-subagent` Flag.

### For Skills That Dispatch Agents (Mandatory)

1. frontmatter `description` mentions `--no-subagent` support
2. `argument-hint` includes `[--no-subagent]`
3. SKILL.md early section adds `## --no-subagent Flag` block listing affected steps and trade-offs
4. Each Agent invocation point has an inline `> --no-subagent mode: ...` annotation
5. README.md flag table gets a new row

### For Skills That Don't Dispatch Agents (Declarative)

1. frontmatter `description` appends `Accepts --no-subagent flag as a no-op (cross-skill consistency, CLAUDE.md Rule 26).`
2. `argument-hint` includes `[--no-subagent]` (preserving existing args)
3. SKILL.md early section adds `## --no-subagent Flag (No-op, Accepted for Consistency)` block; explicitly states "no functional effect" + "accepted for consistency"
4. README.md adds `## 旗標` table row marking **無實際效用（no-op）**

---

## 5. CLAUDE.md Cross-Reference Contract

CLAUDE.md Rule 26 retains:
- **Definition** (what `--no-subagent` means + 強制 vs declarative distinction)
- **Trigger timing** (3 bullets: explicit invocation + 1M context bug + audit trail)
- **`/dispatch` exception** (one line)
- **Pointer to this file** for the full applicable-skill table + implementation template

The applicable-skill catalog (which skills are mandatory vs declarative) and the implementation template for new skills live here.
