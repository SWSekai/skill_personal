# Model 選擇指引

建立新 skill 時，依以下決策樹選擇 `model` 欄位值。

## 決策樹

```
1. 是否使用 Agent 工具做跨檔分析？ ──→ opus
2. 是否需要安全掃描或架構一致性評估？ ──→ opus
3. 是否涉及多步驟編排或需要判斷力？ ──→ sonnet
4. 是否為固定流程的結構化輸出？ ──→ haiku
5. 不確定？ ──→ sonnet（預設）
```

## 速查表

| 條件 | Model | Effort |
|------|-------|--------|
| 用 Agent、跨檔分析、安全審計 | `opus` | `high` |
| 多步驟工作流、檔案讀寫、需判斷 | `sonnet` | `medium` |
| 固定模板、狀態檢查、日誌生成 | `haiku` | `low` |

## Effort 說明

- `high`：深度分析，適合 opus
- `medium`：標準開發任務，適合 sonnet
- `low`：結構化輸出，適合 haiku 或簡單 sonnet 任務
- `max`：僅用於極端複雜場景（罕見）

完整規則參見 `skill_personal/references/model-routing.md`。
