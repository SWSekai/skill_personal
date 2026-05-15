# Cross-Skill References — Section Templates and Rules

> Migrated from CLAUDE.md Rule 24.1 / 24.2 / 24.3.1 (2026-05-15) per CLOSED_260515_todo_root_cause_and_claudemd_slim_decision.md §2.3.a.
> CLAUDE.md keeps the mandatory enforcement clause + pointer to this file; this file holds the section templates and per-direction rules.

---

## 1. SKILL.md Section Template (Mandatory, end of file)

Every skill's SKILL.md MUST end with a `## Cross-Skill References` section in this exact structure:

```markdown
## Cross-Skill References

| Direction | Target | Trigger / Purpose |
|---|---|---|
| → Calls | `<skill or subcommand>` | <step or condition that triggers the call> |
| ← Called by | `<skill>` | <step in caller where this skill is invoked> |
| ↔ Shared Assets | `<file path>` | <purpose of shared resource> |

**Rename History**: see `_bootstrap/RENAME_HISTORY.md`
```

### Column Semantics

| Column | Content |
|---|---|
| **→ Calls** | Skills / subcommands actively invoked by this skill + trigger step |
| **← Called by** | Other skills whose specific step invokes this skill |
| **↔ Shared Assets** | References / assets / hooks co-shared with other skills |

### When No Dependencies Exist

Write `None` in cells, but **do NOT omit the section itself**. The section's presence is the contract; absence is treated as a regression.

---

## 2. README.md Section Template (Mandatory, end of file, 繁中)

Every skill's README.md MUST end with this section in Traditional Chinese:

```markdown
## 相關 Skills 與檔案

- **呼叫**：`<skill / subcommand>` — <觸發時機>
- **被呼叫**：`<skill>` — <觸發步驟>
- **共用資源**：`<file path>` — <用途>
- **改名歷史**：見 `_bootstrap/RENAME_HISTORY.md`
```

無依賴時填「無」，禁止省略段落本身。

---

## 3. Rename History — Single-Line Redirect (Mandatory)

**Why centralized**: `sekai-workflow/_bootstrap/RENAME_HISTORY.md` is the **single source of truth** for all skill renames. Individual SKILL.md / README.md must NEVER carry inline rename details — only a single-line redirect.

| File | Required redirect line |
|---|---|
| SKILL.md | `**Rename History**: see `_bootstrap/RENAME_HISTORY.md`` |
| README.md | `- **改名歷史**：見 `_bootstrap/RENAME_HISTORY.md`` |

No exceptions. Historical archaeology goes through `RENAME_HISTORY.md` or `git log` only.

---

## 4. `/skm sync` Sync Reference

When `/skm sync` detects skill add / delete / rename, the sync uses `_bootstrap/RENAME_HISTORY.md` + current directory structure diff as the authoritative reference — it does NOT rely on inline descriptions in individual skill files. This is why §3 enforces redirect-only.

---

## 5. `/skm new` Step 3 / Step 4 Mandatory Automation

`/skm new` Step 3 (generate SKILL.md) and Step 4 (generate README.md) MUST auto-append these two sections at file end (fill "None" / "無" cells when no dependencies). This is enforced in the create-skill flow.

---

## 6. Violation Handling

| Situation | Action |
|---|---|
| Modifying a skill and discovering the section is missing | Patch in the same commit |
| `/skm sync` detects missing section | Report as integrity violation |
| `/commit-push` Step 1.6 integrity check | Block commit until patched |

---

## 7. CLAUDE.md Cross-Reference Contract

CLAUDE.md Rule 24 retains:
- **Why it exists** (单一定位)
- **What rules SKILL.md and README.md MUST contain** (one-line summary of each section)
- **24.3** Single source of truth (RENAME_HISTORY.md authority)
- **24.5** Violation handling (Step 1.6 enforcement)
- **Pointer to this file** for full template

The full section templates and per-direction column semantics live here.
