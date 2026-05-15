# Pre-modification Protocol — Full Specification

Originally migrated from CLAUDE.md Rule 21.4-21.6 (2026-04-24) per CLOSED_260424_claudemd_slim §3.4.
**Expanded 2026-05-15** per CLOSED_260515_todo_root_cause_and_claudemd_slim_decision.md §2.3.a to also include Rule 21.1-21.3 detail (remote check / risk assessment / user confirmation) — CLAUDE.md keeps a 3-line summary + pointer to this file as always-loaded gate.

---

## 1. Rule 21.1 — Remote Check (Mandatory)

Before any modification:

```bash
git fetch origin
git rev-list --left-right --count origin/main...HEAD
```

Decision tree:
- Remote has new commits (left side > 0) → **pause modification**, ask user to `git pull` (or `git rebase origin/main` depending on divergence type)
- Local and remote trees actually equal (e.g. author-rewrite scenario) → safe to rebase-align with no content conflict
- Bidirectional divergence → enumerate handling options (rebase / reset / new branch) for user to choose

Scope:
- Main project repo (if it's a git repo)
- `.sekai-workflow/` (its own git repo)
- Any other modified git repo touched in this change

---

## 2. Rule 21.2 — Risk Assessment (Mandatory)

Before modification, enumerate:
- **Impact scope**: all files to be touched (skill / runtime mirror / template / manifest / hooks / memo)
- **Potential bugs / risks**: naming collisions, historical-file reference drift, muscle-memory failure, hook regex matcher invalidation, cross-language README out-of-sync, etc.
- **Irreversible operations**: directory rename, `git reset`, file deletion, runtime overwrite — must be explicitly marked and listed in AskUserQuestion options

---

## 3. Rule 21.3 — User Confirmation (Mandatory)

After risk assessment:
- Invoke `AskUserQuestion` or equivalent UI; user must explicitly authorize
- **Forbidden phrasing**: "要繼續嗎？" plain-text Y/N (violates Rule 15)
- Options must distinguish: "low-risk accept default" / "high-risk needs step-by-step" / "cancel and try alternative"
- Modification proceeds only after user reply

---

## 4. Rule 21.4 — When the Protocol Applies

- Modifying project code (pre-existing scope)
- Modifying `.claude/skills/` runtime or `sekai-workflow/` sources (**explicit requirement**)
- Modifying `CLAUDE.md` / `CLAUDE.md.template` / `manifest.json` / hooks
- Cross-skill refactors, command renames, directory moves
- Any operation that will push to a remote

---

## 5. Rule 21.5 — When the Protocol Does NOT Apply

- Pure reads (grep / read / glob / list)
- Single-word replacement within a file already authorized in a rule document
- `AskUserQuestion` invocation itself (meta-operation)

---

## 6. Rule 21.6 — Relation to Rule 15

Rule 15 governs "Y/N confirmation → Tool Confirmation UI". Rule 21 runs **remote check + risk assessment BEFORE the Y/N**, laying out the facts so the user can approve/deny on solid ground. The two are complementary, not overlapping:

| Rule | Scope | Timing |
|---|---|---|
| Rule 21.1-21.3 | Pre-modification gate: fetch, risk, confirm | Before any modification tool call |
| Rule 15 | Y/N confirmation routing | When any Y/N decision is needed |

Violation of either rule is a process gap and must be corrected via `/skm update` or inline rule revision.

---

## 7. Verification

After running the protocol for a given modification:
- Remote check log line visible in conversation ("git fetch origin done; 0 ahead, 0 behind")
- Risk assessment bulleted list visible ("Affected files: X, Y, Z; Risks: naming collision, ...")
- `AskUserQuestion` tool call invoked (not plaintext "要繼續嗎？")
- User approved → proceed; user denied → abort; user gave alternative → follow alternative

If any step missing, the modification was executed in violation of Rule 21.

---

## 8. Relationship to Build Skill Ownership

This reference is placed under `build/references/` because `/build impl` and `/build do` are the primary invocation contexts where large modifications originate. Other skills (`/skm`, `/commit-push`) also trigger Rule 21 and may reference this file.

---

## 9. CLAUDE.md Cross-Reference Contract

CLAUDE.md Rule 21 retains:
- **3-line summary** (fetch + risk + AskUserQuestion as 3 mandatory gates)
- **Pointer to this file** for the full operational detail of each gate

§1-§3 detailed mechanics (commands, decision trees, format rules) live here.

## 1. Rule 21.4 — When the Protocol Applies

- Modifying project code (pre-existing scope)
- Modifying `.claude/skills/` runtime or `sekai-workflow/` sources (**explicit requirement**)
- Modifying `CLAUDE.md` / `CLAUDE.md.template` / `manifest.json` / hooks
- Cross-skill refactors, command renames, directory moves
- Any operation that will push to a remote

## 2. Rule 21.5 — When the Protocol Does NOT Apply

- Pure reads (grep / read / glob / list)
- Single-word replacement within a file already authorized in a rule document
- `AskUserQuestion` invocation itself (meta-operation)

## 3. Rule 21.6 — Relation to Rule 15

Rule 15 governs "Y/N confirmation → Tool Confirmation UI". Rule 21 runs **remote check + risk assessment BEFORE the Y/N**, laying out the facts so the user can approve/deny on solid ground. The two are complementary, not overlapping:

| Rule | Scope | Timing |
|---|---|---|
| Rule 21.1-21.3 | Pre-modification gate: fetch, risk, confirm | Before any modification tool call |
| Rule 15 | Y/N confirmation routing | When any Y/N decision is needed |

Violation of either rule is a process gap and must be corrected via `/skm update` or inline rule revision.

## 4. Verification

After running the protocol for a given modification:
- Remote check log line visible in conversation ("git fetch origin done; 0 ahead, 0 behind")
- Risk assessment bulleted list visible ("Affected files: X, Y, Z; Risks: naming collision, ...")
- `AskUserQuestion` tool call invoked (not plaintext "要繼續嗎？")
- User approved → proceed; user denied → abort; user gave alternative → follow alternative

If any step missing, the modification was executed in violation of Rule 21.

## 5. Relationship to Build Skill Ownership

This reference is placed under `build/references/` because `/build impl` and `/build do` are the primary invocation contexts where large modifications originate. Other skills (`/skm`, `/commit-push`) also trigger Rule 21 and may reference this file.
