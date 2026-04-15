---
name: Skill/機制必須有明確觸發入口
description: 新增 skill 或自動化機制時，必須透過 hooks 或其他方式讓 Claude 有明確的執行觸發點，而非僅靠規則文字
type: feedback
---

新增 skill 或自動化機制時，不能只寫在 CLAUDE.md 規則裡期望 Claude 自行遵守，必須建立明確的觸發入口讓 Claude 知道該執行什麼。

**Why:** 純文字規則容易被忽略（如 Rule 9 三方同步在寫 Memory 時未被觸發）。Hooks 是目前最可靠的自動觸發機制。

**How to apply:**
1. 新增 skill/機制時，評估是否需要 PostToolUse hook 來自動觸發
2. Hook 設定放 `.claude/settings.local.json`（不影響共用帳號）
3. Hook 模板放 `Sekai_workflow/setup/templates/hooks.json`（可移植）
4. sp-init.bat 自動安裝（自動化）
5. 設計原則：不影響共用帳號、可移植、自動化、高效、可轉移、客製化
