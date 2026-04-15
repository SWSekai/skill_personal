---
name: Sekai_workflow 變更後自動推送
description: Sekai_workflow 有變更時直接 commit + push，不要問確認
type: feedback
---

Sekai_workflow/ 有變更時，直接執行 commit + push，不需要詢問使用者是否推送。

**Why:** 使用者認為這是例行操作，每次詢問是多餘的。
**How to apply:** 任何修改 Sekai_workflow/ 內容後（新增/修改 Skill、更新 manifest.json、更新 README），直接在流程尾端自動 commit + push，不發確認訊息。
