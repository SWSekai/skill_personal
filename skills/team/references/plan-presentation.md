# Decision Plan Presentation Pattern

This reference defines the layout convention for `/team decide` files when Claude offers **pre-bundled recommended combinations** alongside item-by-item selection. Used when a decision spans many sections (≥6) and granular per-item checking burdens the user.

Originated 2026-04-29 from PDF_Detector CNN training decision — user requested this pattern be retained for future conflict-handling and selection presentation.

## 1. When to use this pattern

Add a "**§N 兩套推薦組合（快速決定路徑）**" block to a decision file when ALL hold:

- The decision file has ≥ 6 sections requiring user input
- Two coherent end-to-end strategies are pre-identifiable (e.g. "成熟生態優先" vs "輕量自訂", "全面重寫" vs "增量重構")
- The user benefits from a one-click "採用方案 X" instead of touching every section

Skip this pattern when:
- Only 1–5 sections → section-by-section is fast enough
- Only one viable strategy exists → describe in opening 背景 instead
- Plans would force unrelated bundling (don't fabricate two strategies just to fit the template)

## 2. Required structure

Place near the file end, **AFTER** all per-section blocks but **BEFORE** 風險與待確認:

```markdown
## §N 兩套推薦組合（快速決定路徑）

> 不想逐項勾選，可直接選下列其中一套，再針對 §X、§Y 補上專案細節即可。

### 方案甲：**<簡稱>（<一句定位>）**
- §1 = a（<簡述>）
- §2 = b
- ...

**Trade-off**：<甲的長處>；但 <甲的短處>。

- [ ] **採用方案甲**

### 方案乙：**<簡稱>（<一句定位>）**
- §1 = a
- §2 = c
- ...

**Trade-off**：<乙的長處>；但 <乙的短處>。

- [ ] **採用方案乙**

### 方案丙：**自由組合**（不採用甲/乙整套）

- [ ] **採用自由組合**（按 §1–§N 個別勾選結果為準）

**補充說明：**
> 💡 預填建議：<Claude 推薦哪個方案 + 一句理由>。本欄為「方案 vs 自由組合」conflict-handling 入口，後續 Claude 回應一律以 `>` callout 嵌入此區（規則出處：`references/plan-presentation.md`）。
> _(請填：偏好甲、乙、丙？理由？)_
```

## 3. Claude response in this section MUST use `>` callout (mandatory)

Per CLAUDE.md Rule 17 + `claude-response-format.md`: when the user

1. checks **採用方案 甲 / 乙 / 丙** (any of the three plan checkboxes), AND
2. adds a question, directive, or counter-proposal in `補充說明：` blockquote (e.g. "請評估與我自行勾選的差異")

→ Claude responds **inside the same `補充說明：` blockquote** following the email-thread pattern in `claude-response-format.md`. The `>` blockquote callout is **non-optional** — bullet-list responses below the section break the visual coherence and parser expectation.

### Required response anatomy (Round 1)

```markdown
**補充說明：**
> 💡 預填建議：方案乙。<original reasoning, never updated>
> <user's question / directive>
>
> 📝 **Claude 回應（YYYY-MM-DD）— <一行結論>**
>
> **差異對照表**
>
> | 項目 | <方案 X 配方> | <你的勾選 / 方案 Y> | 衝擊 |
> |---|---|---|---|
> | §a.b | ... | ... | ... |
>
> **<關鍵衝突 / 副作用 標題>**
>
> <分析 body>
>
> **建議方向**
>
> 1. ...
> 2. ...
>
> **規則更新（如使用者要求）**
>
> - ...
```

Round 2+ wraps Round 1 in `<details>` per `claude-response-format.md` §4.

## 4. Conflict-handling expectation (when user picks plan X but section checks diverge)

When the user selects **採用方案 X** but their per-section checks diverge from X's recipe, Claude **must**:

1. Identify the divergent sections in the response body's 差異對照表
2. For each divergence row: show 方案 X 配方 / 使用者勾選 / 衝擊
3. Flag any cross-section conflicts (e.g. §02 model + §04 input size mismatch)
4. Propose folding (per-section check **wins** over plan label by default — plan is a recommendation, sections are the source of truth) OR explicitly ask which to override
5. If divergence creates a NEW conflict not previously analyzed → propose a 折衷 (third path) and require user confirmation before proceeding

## 5. Why two-plan + free-combo (not just plans)

The 自由組合 escape hatch is **mandatory** because:

- Pre-bundled plans are opinionated — they serve the common case but cannot anticipate every project nuance
- Forcing the user into 甲 or 乙 collapses the section-by-section grain that may matter for a specific decision (e.g. user might want 甲 except for §3 = c instead of b)
- Free-combo defers to per-section checks, recovering full granularity
- Same trade-off as Rule 17.3「複選題必附『全部都做』」at a higher level: provide the easy default but never close the bespoke path

## 6. Anti-patterns

- ❌ Listing 3+ pre-bundled plans (overwhelms; 甲 / 乙 + 自由組合 is the cap; if a third strategy is viable, it usually means the two are not coherent enough — refactor the per-section options instead)
- ❌ Bullet-list response under `**補充說明**（請填）：- 問題` — must convert to `補充說明：\n> 💡 預填建議：...\n> 問題` blockquote pattern
- ❌ Updating `💡 預填建議` line during exchange (immutable per `claude-response-format.md` §3; updates go in response body)
- ❌ Putting plans BEFORE per-section blocks (per-section is the canonical source; plans are convenience overlays — must come after to make the relationship visually obvious)
- ❌ Plans referencing sections that don't exist or contradicting per-section labels without flagging
- ❌ Skipping the conflict-handling response when divergence is obvious (the whole point of the pattern is to make divergence first-class)

## 7. Relationship to other references

- `claude-response-format.md` — full response embedding rules (this file references but does not duplicate)
- `naming.md` §5.2 — closure summary template (preserved on `CLOSED_` rename, including any `>` callout responses in plan section)
- `four-tools-exclusivity.md` §3 (Rule 17.1.2) — when to use AskUserQuestion vs decide; this pattern only applies once decide is open
- `interaction-modes.md` — additional interaction modes (single-select / multi-select / hybrid)

## 8. Migrating legacy decision files

Decision files predating this reference (e.g. with `補充說明（請填）：- 問題：?` bullet format):
- On next interaction with the file → Claude converts to canonical blockquote (`💡 預填建議` + user line + response inside `>`)
- Original bullet content preserved verbatim inside the `>` block — do not strip
- File-level rename or relocation NOT required (legacy paths stay; only inline format upgrade)

## 9. Failure mode: plans become stale after edits

If the user edits per-section options after plans were drafted, plan recipes can drift (e.g. plan says §4 = b but option b was renamed). Detection / repair:

- On every read of a decision file with plan block → Claude verifies each plan's `§N = x` references resolve to valid options
- Mismatch found → flag in the response body's 差異對照表 row "plan stale"; ask user whether to fix the plan or fall through to per-section
- If plans become unmaintainable across many edits → suggest migrating to free-combo only and dropping the plan block
