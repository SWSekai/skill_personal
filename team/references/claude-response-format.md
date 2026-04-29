# Claude Response Format Inside Interactive Documents

Applies to `/team decide` and `/team board` files. When the user both (1) checks an option AND (2) modifies the `補充說明：` blockquote with a question / directive, Claude responds **embedded inside the same `補充說明：` blockquote**, below the user's line(s). Response format follows an email-thread pattern: newest reply stays expanded; older replies fold into `<details>` when a subsequent round arrives. The `💡 預填建議` prefill line does **not** dynamically update — updates go only into the response body.

## 1. Trigger condition (strict — both signals required)

Respond inline **only when all** of the following hold:
1. The section's checkbox has been ticked (`[x]` on some option — any option, including `其他`)
2. The `補充說明：` blockquote has been modified — user added at least one line beyond the original `💡 預填建議` line
3. The added content is a question / challenge / directive / clarification request (not just a passive comment)

If only one of (1) or (2) is present → do NOT write an inline response. Stay silent and handle via CLI only if needed.

Do **not** apply:
- One-off CLI chat answers unrelated to any decision file
- Closure summary blocks (those follow `references/naming.md §5.2`)
- Sections where only the checkbox changed with no supplementary text
- Sections where only text was added with no checkbox selection
- Sections where Claude would merely repeat the `💡 預填建議` — no new information

## 2. Position (embedded inside blockquote)

Response lines go **inside the `補充說明：` blockquote** — every line prefixed with `> `. NOT as a plain block below the blockquote.

Base form (Round 1):
```markdown
**補充說明：**
> 💡 預填建議：§N.M.a。<original reasoning — stays unchanged>
> <user's question / directive>
>
> 📝 **Claude 回應（YYYY-MM-DD）— <one-line gist>**
>
> <response body>
> <each line `> ` prefixed, including tables and lists>
> 
> | col | col |
> |---|---|
> | a | b |
```

Empty lines inside the response use a bare `>` to keep blockquote continuity.

## 3. `💡 預填建議` line is NOT dynamically updated

The `💡 預填建議` line set at document generation time **stays as-is** throughout the exchange. Do not append `（YYYY-MM-DD 更新）` suffixes or revise the recommendation text.

If Claude's analysis during the exchange shifts the recommendation:
- State the shift **inside the response body**
- Do NOT edit the original `💡 預填建議` line
- Rationale: the prefill represents Claude's initial judgement at doc-generation time. Mutating it erases the thought trail. Response body is the proper place for updated views, letting readers see the evolution.

## 4. Email-thread pattern (Round 2+)

When the user adds a follow-up after seeing Round 1, retroactively wrap Round 1 in `<details>` (still inside the blockquote) and append Round 2 plain below:

```markdown
**補充說明：**
> 💡 預填建議：§N.M.a。<original reasoning, unchanged>
> <user's original question>
>
> <details>
> <summary>📝 Claude 回應（YYYY-MM-DD）— Round 1 gist</summary>
>
> Round 1 body
>
> </details>
>
> <user's follow-up question>
>
> 📝 **Claude 回應（YYYY-MM-DD）— Round 2 gist**
>
> Round 2 body
```

Round 3+: same pattern — collapse Round 2 into `<details>`, append Round 3 plain. Only the newest response is plain; all older folded.

## 5. Summary-line format

**Folded round** (wrapped in `<details>`):
```html
<summary>📝 Claude 回應（YYYY-MM-DD）— <one-line gist></summary>
```

**Plain round** (latest, not folded):
```markdown
📝 **Claude 回應（YYYY-MM-DD）— <one-line gist>**
```

- Date from `date '+%Y-%m-%d'` (see `naming.md §2` time sampling), not context `currentDate`
- Gist is 5-15 words, states the conclusion / action in one phrase
- `📝` emoji prefix consistent across folded and plain — matches `💡` convention for prefill

## 6. Preservation on closure

When decide Step 6 / board Step 3 runs inline closure summary + rename:
- All response blocks (plain and `<details>`-wrapped) inside `補充說明：` blockquotes **must be preserved** in the `CLOSED_` file
- Do NOT unfold `<details>` on closure; keep historic collapsed state
- Do NOT fold the latest plain response on closure
- Closure summary goes at file end as separate `# 結案摘要（Closure Summary）` block

## 7. Parsing implications

Follow-up parsers (`references/followup.md`) and daily-report extractors (`references/daily-report.md` §9) should:
- Treat `📝 **Claude 回應...**` heading lines AND `<details>...</details>` HTML inside blockquotes as inert for `[x]` counting and supplementary-note extraction
- Still extract the prefill `💡 預填建議` line as the original recommendation anchor
- Not confuse these in-section response markers with file-end closure summary heading

## 8. Anti-patterns

- ❌ Responding inline when only checkbox changed or only text changed (violates §1 strict both-signals rule)
- ❌ Placing response BELOW the `補充說明：` blockquote as a plain heading (violates §2 — must be embedded inside)
- ❌ Updating the `💡 預填建議` line with `（YYYY-MM-DD 更新）` or revised recommendation (violates §3)
- ❌ Wrapping Round 1 in `<details>` on first write (should stay plain)
- ❌ Leaving old rounds plain when Round N+1 arrives (previous round must retroactively fold)
- ❌ Editing the user's blockquote lines to insert the answer
- ❌ Using `**補充說明**:` with ASCII colon (must be `**補充說明：**` full-width colon)
- ❌ Omitting `💡` / `📝` emoji prefixes
- ❌ Writing `預填建議` outside `>` blockquote — icon alone is insufficient; the `>` callout provides the visual container that separates Claude's suggestion from surrounding text (icon for recognition, callout for readability)
- ❌ Writing `補充說明：` content (user text, prefill, Claude responses) without `>` prefix — all content inside the 補充說明 block must stay inside the blockquote
- ❌ Omitting date stamp in gist
- ❌ Forgetting `> ` prefix on response body lines (breaks blockquote)

## 9. Rationale

Interactive documents are the single source of truth for the decision / discussion. Embedding Claude responses inside the `補充說明：` blockquote keeps all exchanges on a section contained in one visual block — scroll, grep, and `CLOSED_` archival all see a single coherent unit. The strict both-signals trigger prevents noise: a user who checks a box without comment has decided; a user who comments without checking is thinking out loud; only when both happen has a genuine question been posed. Not updating `💡 預填建議` preserves the original judgement trail — future readers see both the first instinct and the refined analysis, not an overwritten single line that erases history. Email-thread folding keeps the file scannable as rounds accumulate; `💡` / `📝` emojis visually separate Claude content from user blockquote lines.
