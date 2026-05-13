---
name: 使用者給推進方向時主動寫入 TODO
description: 使用者選定方向、列舉新工作或下達指派時，必須在同回覆內主動寫入 ./TODO.md，不依賴使用者再次提醒
type: feedback
---

使用者透過對話、`AskUserQuestion` 回應或自由文字給出工作推進方向（如 A/B/C 選擇、列舉項目、明確指派）後，**必須在同一回覆中主動寫入 `./TODO.md` 的對應區塊**（Pending / In Progress / Completed），不可等下一輪或讓使用者再開口要求。

**Why:** PDF_Detector 2026-05-13 session 中，使用者於 AskUserQuestion 中選定 A、D 方向後 AI 未自動同步 TODO.md，使用者必須補加「請紀錄至 TODO，之後你必須主動紀錄」才觸發。Memory／TaskList／TODO.md 三層中：
- Memory 是跨 session 偏好，但不是工作清單
- TaskList 是 session 內任務，VSCode 重開後消失
- **TODO.md 是「跨 session 持久化 + 使用者直覽 + 崩潰恢復」的唯一錨點**

只有同步寫入 TODO.md 才能保證使用者下次回到專案能直接看到「上次選了什麼方向、目前做到哪」。

**How to apply:**
- 使用者在 `AskUserQuestion` 中選一個方向 → 立即 Edit TODO.md 加 Pending 項；reply 中明確告知「已加入 TODO.md」
- 使用者在自由文字列舉「做 X、做 Y」→ 拆解後逐項加 Pending
- 使用者跳過先前選項並直接給新指示 → 把跳過的選項忽略，新指示寫入 TODO（不要保留漂浮選項）
- 寫入時依優先級（`@high` / 預設 / `@low`）、附觸發條件或來源 commit hash
- 若使用者只是「探討」而未做選擇 → **不**寫入 TODO；以「探討即記錄」會污染清單
- 適用範圍與 CORE Rule 9 相同：**任何**涉及多檔修改或多步驟的實作流程
