# Skill Folder Structure — SKILL.md External Contract vs references/ Detail

Migrated from CLAUDE.md Rule 19.2-19.5 (2026-04-24) per CLOSED_260424_claudemd_slim §3.2. Rule 19.1 (subdirectory responsibilities table) stays in CLAUDE.md as the primary reference.

## 1. SKILL.md External Contract — What MUST Be Present

- frontmatter (name, description, model, argument-hint, allowed-tools)
- Subcommand routing (overview table)
- Common rules (cross-subcommand shared rules — time sampling, filename conventions, closure markers)
- Per-subcommand: Usage + Steps (Step 1-N outline; detail references `references/<detail>.md`)

## 2. Forbidden in SKILL.md — Move to references/

- Parser logic / regex rules
- Data structure definitions
- Multi-page flow details (> 3 nested sub-steps → split out)
- Template strings (belongs in `assets/`)

## 3. Migration Timing for Old Skills

Per `260422_reference_convention_propagation_decision.md §1.1.c`: new skills must adopt; old skills migrate opportunistically when modified. Do NOT undertake large-scale refactors just for structure compliance on stable skills.

## 4. Reference File Language

Reference files match the corresponding SKILL.md language. Current SKILL.md = English → references = English. Output template examples inside reference files may retain the project language (Traditional Chinese) for the actual output templates Claude renders to the user.

Example (in an English reference for a Chinese-project skill):
- Rule text: English ("The closure summary must be appended at file end...")
- Embedded Chinese output template: retained Chinese ("# 結案摘要（Closure Summary）")

## 5. Relationship to Rule 19.1

Rule 19.1 in CLAUDE.md lists the four subdirectories (`references/` mandatory; `assets/`, `agents/`, `scripts/` optional) with their responsibilities. This file provides the detailed contract for what content belongs where — complement, not duplicate.
