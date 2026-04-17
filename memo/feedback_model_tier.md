---
name: Skill Model 三層分工原則
description: 規劃/評估/架構決策用 Opus；標準執行用 Sonnet；純文字撰寫與日誌產出用 Haiku
type: feedback
originSessionId: dddfa0de-6667-4adc-83a2-bc6db4a98bad
---
規則內容：所有 Skill 與工作流程的 model 指派遵循三層原則：

- **Opus**：評估、規劃、架構決策、深度品質分析、跨檔案影響追蹤、需要 thinking 的工作
- **Sonnet**：多步驟執行、檔案讀寫、標準開發任務、中低複雜度工作（執行屬性）
- **Haiku**：結構化文字撰寫、模板填充、狀態檢查、日誌產生（純文字產出）

**Why:** 使用者於 2026-04-15 `commit-push` Skill 架構重整對話中明示：「大原則上，評估、規劃等需要 thinking 的工作交由 Opus 處理，而後交由 Sonnet 去執行，並且若複雜度不高的工作也可以交由 Sonnet，文字的撰寫則可以交給 Haiku」。此原則取代先前「寫入統一由 Sonnet 執行」的較粗略界線，提供更精細的模型成本 / 能力分配。

**How to apply:**
- Skill frontmatter 的 `model:` 欄位依主要工作屬性決定（plan/quality → opus；commit/impl/test → sonnet；log → haiku）
- 單一 Skill 若需跨層能力（例如 `/commit-push` 主體 Sonnet、Step 1 品質檢查需 Opus、Step 5 日誌需 Haiku），透過 Agent 工具呼叫對應 model 的子任務，不改變 Skill 本體 model
- Commit 的 Co-Author 字串依**實際執行的 model** 動態填入（`Claude Sonnet 4.6` / `Claude Opus 4.6` / `Claude Haiku 4.5`），禁止使用無版本的 `Claude <noreply@anthropic.com>`
- 多 model 協作時最多列兩行 Co-Author（主執行者 + 次要貢獻者）
- 新建 Skill 時，`/skill new` 必須引導使用者選擇正確 model 層級

此規則已寫入 `CLAUDE.md` 第 18 條（強制層級），並於 `sekai-workflow/build/SKILL.md` 與 `sekai-workflow/commit-push/SKILL.md` 的 model 分層表中實作。
