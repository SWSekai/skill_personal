# Rule / Skill Change Follow-up Checklist (Reference)

> Migrated from CLAUDE.md Rule 27.2 (2026-05-15) per CLOSED_260515_todo_root_cause_and_claudemd_slim_decision.md §2.3.a.
> CLAUDE.md keeps Rule 27 trigger timing + Step 1.6 enforcement + failure-rollback rule. This file holds the per-change-type checklist used during `/commit-push` Step 1.6.

---

## 1. Trigger Timing (CLAUDE.md Rule 27.1 — kept in CLAUDE.md)

Triggered by any of:
- `CLAUDE.md` rule add / modify / remove
- `_bootstrap/templates/CLAUDE.md.template` corresponding change
- Skill `SKILL.md` frontmatter change (description / model / argument-hint / allowed-tools) or significant step structure change (Step count / order / dependency)

**Not triggered** (per CLAUDE.md Rule 27.1):
- Pure text typo
- Example snippet micro-adjustments
- Punctuation / formatting tweaks

---

## 2. Per-Change-Type Checklist (Rule 27.2 — full table)

| Change Type | Required Follow-up Items |
|---|---|
| Path migration / command rename | Append one line to `.hanschen/.history/refactor.jsonl` |
| Cross-skill behavior change | Update both skills' SKILL.md / README.md `Cross-Skill References` sections (Rule 24) |
| New sync detection item | Update `/team sync --audit` detection logic (`skills/team/SKILL.md` Step §I.2) |
| Affects pre-commit check | Update `/commit-push` Step 1.6 integrity checklist |
| Rule extends to all skills | Sync to `_bootstrap/templates/CLAUDE.md.template` for other projects |
| Affects hook behavior | Update `.claude/hooks/*.cjs` and corresponding settings.json matcher |
| Path constants / canonical paths | Verify CLAUDE.md, all SKILL.md, all README.md, all references / for stale path strings (grep) |
| Cross-skill end-step contract | Confirm consuming skills cross-reference the owning skill, no duplicated definitions |

---

## 3. Enforcement Mechanism (Rule 27.3 — kept in CLAUDE.md)

`/commit-push` Step 1.6 "Rule / Skill Integrity Check" detects:
- Whether this commit contains `CLAUDE.md` / `CLAUDE.md.template` / any `SKILL.md` change
- If yes → displays §2 checklist; user must confirm each item handled or declare "not applicable for this change"
- Any item unhandled and no "not applicable" declaration → **block commit**

---

## 4. Failure-Rollback Rule (Rule 27.4 — kept in CLAUDE.md)

If a follow-up item is missed and discovered after commit:
1. Add the follow-up (do NOT amend the existing commit)
2. Open a new commit
3. commit message includes `(rule-27 followup: <item>)` tag for traceability

---

## 5. CLAUDE.md Cross-Reference Contract

CLAUDE.md Rule 27 retains:
- **27.1** Trigger conditions (5 bullets)
- **27.3** Step 1.6 enforcement statement (one line)
- **27.4** Failure-rollback rule (one paragraph)
- **Pointer to this file** for full §2 per-change-type checklist

The per-change-type detailed table (§2) and the operational instructions live here.
