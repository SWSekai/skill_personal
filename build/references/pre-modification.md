# Pre-modification Protocol — Scope, Exclusions, Relation to Rule 15

Migrated from CLAUDE.md Rule 21.4-21.6 (2026-04-24) per CLOSED_260424_claudemd_slim §3.4. Core enforcement (21.1 remote check, 21.2 risk assessment, 21.3 user confirmation) stays in CLAUDE.md as always-loaded mandatory gates. This file holds the meta-documentation: when the protocol applies, when it doesn't, and how it relates to Rule 15.

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
