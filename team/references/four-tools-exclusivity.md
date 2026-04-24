# Four-Tools Exclusivity and Transition Rules

Migrated from CLAUDE.md Rule 17.1.1-17.1.6 and 17.1.9 (2026-04-24) per CLOSED_260424_claudemd_slim §3.1. Exceptions retained in CLAUDE.md: §17.1.7 (future-trial items → TODO) and §17.1.8 (auto-create TODO.md) — both trigger in general conversation without `/team` skill invocation, so they must remain in the always-loaded CLAUDE.md layer. §17.1.10 (Claude inline response format) also remains in CLAUDE.md as it governs in-file Q&A behavior outside explicit skill invocation.

## 1. Four-Tools Overview Table

"Four tools" = TODO / board / decide / journal (`/team todo` / `/team board` / `/team decide` / `/team journal`). `/team report --daily` is a mode of the report subcommand, **not a fifth independent tool**.

| Feature | decide (`decisions/`) | board (`whiteboards/`) | TODO (`TODO.md`) | PROJECT_JOURNAL |
|---|---|---|---|---|
| **Core question** | Choose A, B, or C? | Where is this topic? | What else to do? | What has the project done / why? |
| **User action** | Check options | Multi-round supplementary | Item checkoff | Read (not hand-write) |
| **Mutually exclusive branching options** | ✅ required | ❌ | ❌ (already decided) | ❌ |
| **Lifecycle** | Implementation done → `CLOSED_` | Closure → `CLOSED_` | Persistent single file | Append-only permanent |
| **Convergence** | Inline summary + rename + PROJECT_JOURNAL index | Inline summary + rename + PROJECT_JOURNAL index | Completed items move to archive | board/decide closure auto-append |
| **Auto trigger** | ❌ **forbidden auto** (chain from board→decide allowed) | Consultation "3 rounds without convergence" auto-create | "btw / 順便 / 臨時想到" silent append to Pending | Auto-append index after closure |
| **Disallowed** | Single-line bug fix, simple A/B (use AskUserQuestion) | One-off Q&A, task already clear | Items needing decision, >200 chars, branching | Manual edit (violates auto-index) |
| **Transition** | Closure implementation items → auto-append TODO | Mutually exclusive decision emerges → open decide sub-doc with link | Contains decision items → tag `@needs-decide` + open decide | None (one-way terminal) |

## 2. Rule 17.1.1 — TODO "btw / 順便" Auto-Capture

When conversation contains "btw / 順便 / 臨時想到 / 對了":
1. Do NOT interrupt the main task
2. Internally call `/team todo add <text>` to append to Pending
3. End of reply: one-line hint "已將『<簡述>』加入 TODO Pending"
4. Content > 200 chars or contains "A 還是 B" branching → also hint "可升級為 /team decide，要開嗎？"
5. User explicitly refuses ("不用記") → do not add

## 3. Rule 17.1.2 — decide A/B Dual Mode

| Scenario | Tool |
|---|---|
| Options need no spec discussion (color, preset, display preference) | `AskUserQuestion` directly |
| Options need weighing, pre-fill, current-state comparison, supplementary notes | Open `decide` file via Rule 17 full flow |

Heuristics: option description fits in 5 words → AskUserQuestion; needs impact scope, risks listed → decide; user explicitly says "幫我開決策檔" → decide (intent priority); unsure → default to AskUserQuestion (can upgrade later).

## 4. Rule 17.1.3 — board 3-Round Auto-Trigger

Consultation / planning / troubleshooting conversations **with 3 rounds of back-and-forth without convergence** → auto-create `.local/docs/whiteboards/YYMMDD_<topic>_board.md`. 1-2 rounds with quick convergence → do not open whiteboard.

## 5. Rule 17.1.4 — Transition Flows

- Whiteboard reveals mutually exclusive decision → open decide sub-file inside whiteboard, link reference
- TODO item needs architectural decision → tag `@needs-decide` + open separate decide; after decide closure, TODO item appends link
- After decide / board closure: change list's **implementation items** AND **unresolved leftover items** (`未解決遺留項`) both auto-append to TODO with `(from CLOSED_*_decision.md)` or `(from CLOSED_*_board.md)` tag. (2026-04-24 expanded: was implementation-only; now covers leftover items per feedback — 遺留項 dropping into TODO ensures they don't get forgotten after CLOSED archival)
- journal vs daily report: journal permanent index (CLOSED history); daily report is today's active page (TODO / closure / commit / handoff)

## 6. Rule 17.1.5 — Anti-Pattern Detection (Advisory Mode)

Detected cases → prompt via `AskUserQuestion`: "像 X 誤用，建議 Y", user decides (non-blocking):
1. Decision-needing items stuffed into TODO (e.g., "Redis or Memcached" doesn't belong in TODO)
2. Single-line bug fix opens decide (over-documentation)
3. Whiteboard opened with only one Q&A (should be TODO or conversation)
4. PROJECT_JOURNAL manually edited (violates auto-index)
5. daily report covers cross-week data (should use `/team report weekly`)

## 7. Rule 17.1.6 — "brief" Term Removed (2026-04-24)

Early term "brief" referred to daily Teams report; term removed. Replacements: `YYMMDD_daily_report.md`, `references/daily-report.md`, `assets/daily-report-template.md`, "每日報告". Actual tool remains `/team report --daily`. "brief" no longer an independent concept.

## 8. Rule 17.1.9 — Misuse Penalty List (Consolidated)

Supplementary to §17.1.5 anti-pattern detection — the "penalty" dimension:
- Stuffing "user-decision items" into TODO → loses option context
- Opening decide for single-line todo → over-documentation
- Leaving "one-off decision" in whiteboard → accumulates stale info
- Stuffing "future trial items" into decide → reduces decide signal-to-noise; marginalizes TODO mechanism

## 9. Relationship to CLAUDE.md

CLAUDE.md retains the headline rule (§17.1 four-tools exclusivity with condensed table), §17.1.7, §17.1.8, and §17.1.10 — these fire in general conversation without explicit `/team` invocation. All other subrules (17.1.1-17.1.6, 17.1.9) live here for `/team` skill's on-demand loading.
