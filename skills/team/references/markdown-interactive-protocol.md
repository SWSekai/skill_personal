# Markdown Interactive Document Protocol — Full Specification

> Migrated from CLAUDE.md Rule 17 (2026-05-15) per CLOSED_260515_todo_root_cause_and_claudemd_slim_decision.md §2.2.a.
> CLAUDE.md keeps the trigger condition + applicable / non-applicable list + cross-reference pointer; this file holds the full operational detail.
> Owner: `/team decide` + `/team board`.

---

## 1. Document Location and Naming

| Document Type | Path | Filename Format |
|---|---|---|
| Decision table | `.hanschen/decision/` | `YYMMDD_<topic>_decision.md` |
| Whiteboard | `.hanschen/board/` | `YYMMDD_<topic>_board.md` |
| Closed (post-implementation) | same directory | `CLOSED_` prefix prepended |

Naming details: see `naming.md` §1-§5.

---

## 2. Interactive Element Requirements

The document MUST support all of the following so the user can edit inline rather than reply in CLI:

| Element | Format |
|---|---|
| **Checkbox** | `- [ ] **§N.M.a** option label` |
| **Pre-filled recommendation** | Claude pre-checks `- [x] **§N.M.a**` for its suggested option |
| **Current state vs proposed** | "Current: X" line + option list mapping each to delta |
| **Global numbering** | `§1`, `§1.1`, `§1.1.a` — supports precise reference in chat |
| **Other (fill in 補充說明) option** | Every decision block MUST include `- [ ] **§N.M.d** 其他（填補充說明）` to let user override defaults |
| **補充說明 field** | Mandatory block at end of each `§N.M`; never blank |

---

## 3. 補充說明 Field — Visual Format (Mandatory)

```markdown
**補充說明：**
> 💡 預填建議：<Claude pre-filled suggestion content>
```

Rules:
1. **Label**: `**補充說明：**` — bold + 全形冒號（U+FF1A）
2. **Prefill line**: `> 💡 預填建議：<content>` — `>` callout wrapping + 💡 icon prefix
3. **Why this format**: icon adds recognizability; `>` callout improves human visibility; user can locate "where to fill, what Claude suggests" at a glance
4. **Prefill content (mandatory) must**:
   - Hint what type of content is expected
   - Explain trade-offs between options
   - State Claude's default recommendation with reasoning
   - Allow user to accept verbatim or rewrite

---

## 4. CLI Reply Responsibilities

After creating the document, the CLI reply is responsible **only** for:
1. Telling the user the document path
2. Summarizing the key decision points (1-3 sentences)
3. Waiting for the user to either:
   - Mark options + reply "OK / 完成" → Claude re-reads, parses 補充說明, generates change summary, executes
   - Modify the document via comments / new lines → Claude responds inline per §6

The CLI reply MUST NOT contain the full decision content (that lives in the document).

---

## 5. Post-Implementation Workflow (Mandatory, 2026-04-22 revised)

After execution completes:

1. **Append inline closure summary** to the original file's end (preserve all original §1-§N checkboxes + 補充說明 intact)
2. **Rename** the original file to `CLOSED_YYMMDD_<topic>_decision.md` (or `_board.md`) — **do not delete**, permanently retained
3. **Inline summary content** must include:
   - 背景 (original problem summary)
   - 最終決策 table (per §N.M: adopted option + user 補充)
   - 變更清單 (files + commit hash)
   - 🔖 保留候選 (only for non-single-path decisions, see §7 below)
   - 未解決遺留項
4. `.local/docs/summary/` is **no longer created** (directory removed 2026-04-22)
5. The CLOSED_ file's inline summary is the **read-only authoritative record** — sole source of truth for "where did decision X come from"
6. Unified template: see `naming.md` §5

---

## 6. In-File Q&A Response Format (CLAUDE.md Rule 17.1.10 — kept in CLAUDE.md)

The strict trigger rule (checkbox `[x]` + user-added 補充說明 line) stays in CLAUDE.md as always-loaded enforcement. This section holds the format detail.

**Round 1 format**:

```markdown
**補充說明：**
> 💡 預填建議：<原始，永不變>
> <使用者問題>
>
> 📝 **Claude 回應（YYYY-MM-DD）— <一行結論>**
>
> <response body — every line `> ` prefixed>
```

**Round 2+ format**: Round 1 collapses into `<details>` (still inside the blockquote); Round 2 plain content placed below. Email-thread style.

**Three core rules** (CLAUDE.md Rule 17.1.10 enforcement):
1. **Response embedded in blockquote** — every line `> ` prefixed, NOT under a separate heading below the blockquote
2. **`💡 預填建議` never dynamically updated** — original prefill is permanent; corrections / expansions go into the response body
3. **Strict trigger**: the block's checkbox MUST be `[x]` **AND** 補充說明 must have user-added lines (not just prefill); only-checkbox or only-edit do not trigger

Full format: see `claude-response-format.md`.

---

## 7. Non-Single-Path Decision Candidate Retention (avoid future redesign)

Decision options are classified as either:
- **Single-path** (mutually exclusive): selecting A excludes B → only record final selection, do not retain unselected
- **Non-single-path** (co-existing): features / feature flags / additional enhancements → retain unselected with reason and restart timing

Non-single-path candidate retention rules:
- Inline summary contains a **🔖 保留候選（未採納但可重啟）** block listing unselected options + reason + restart timing
- Candidate cleanup: unvisited > 6 months or superseded by new decision → mark "已作廢" but **do not delete** (preserve history)
- When new conversation encounters similar need → **read 保留候選 first**, evaluate restart instead of redesigning

---

## 8. Applicable / Non-Applicable (CLAUDE.md Rule 17 entry condition — kept in CLAUDE.md)

CLAUDE.md retains the entry criteria (always-loaded). Reference summary:

**Applicable** (must open decide / board):
- Multi-file refactor plans
- New feature design
- Architecture / technology choice
- Skill or rule flow changes

**Non-applicable**:
- Single-file bug fix
- One-shot information query
- Items already in TODO execution list
- Pure code refactor without architectural impact

---

## 9. Owner and Cross-References

- **Decision tables**: owned by `/team decide` (SKILL.md §C)
- **Whiteboards**: owned by `/team board` (SKILL.md §B)
- **Q&A response format**: shared by both (§C Step 3.5 + §B Step 2.5); detail in `claude-response-format.md`
- **Four-tool exclusivity** (decide / board / TODO / journal): see `four-tools-exclusivity.md`

CLAUDE.md only retains the trigger condition + cross-reference pointer to this file.
