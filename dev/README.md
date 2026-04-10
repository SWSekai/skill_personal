# /dev — 開發流程合併 Skill

整合 commit-push、quality-check、modify-log、restart-eval、restart-volumn 五個原始 Skill。

## 使用方式

| 指令 | 說明 |
|---|---|
| `/dev` 或 `/dev commit [msg]` | 完整提交流程（品質檢查 → 日誌 → README → commit → push → 重啟評估） |
| `/dev quality [files]` | 獨立品質審計 |
| `/dev log [topic]` | 建立 / 更新本地修改日誌 |
| `/dev restart [services]` | 容器重啟與自動修復 |
| `/dev eval [range]` | 重啟評估（不執行） |

無參數時預設執行 `commit`。

## Model

- **Skill model**：`sonnet`
- **commit / log / restart / eval**：標準步驟，sonnet 即可
- **quality**：需深度分析；於子命令內以 deeper thinking 完成（必要時呼叫 Agent）

## 觸發

- 手動：使用者呼叫 `/dev <subcommand>`
- 自動：無

## 主要流程

### `/dev commit`
1. 呼叫 quality 子命令做品質審計（含資料流重讀）
2. 自動更新 README
3. 列出 staging 狀態
4. Commit（Conventional Commits + Co-Authored-By）
5. 呼叫 log 子命令寫修改日誌
6. Push
7. 同步 .skill_personal/ 至遠端
8. 呼叫 eval 子命令輸出重啟指令
9. 經驗回流至 `.local/docs/<guide>.md`

### `/dev quality`
死碼/冗餘/硬編碼/錯誤處理/型別/序列化/安全性掃描，加架構一致性、影響評估、風險報告、資料流重讀。

### `/dev log`
寫入 `.local/modify_logs/YYMMDD_TopicDescription.md`，僅本地。

### `/dev restart`
Pre-flight → 執行 → 健康檢查 → 日誌掃描 → 自動修復 → 最終驗證。

### `/dev eval`
從 git diff + docker-compose 推導每個變更檔對應的服務動作，輸出指令清單。

## 檔案結構

```
.claude/skills/dev/
├── SKILL.md
└── README.md
```

無 references/、assets/、scripts/ 子目錄，所有邏輯內含於 SKILL.md。

## 對應原 Skill

| 原 Skill | 子命令 |
|---|---|
| commit-push | `/dev commit` |
| quality-check | `/dev quality` |
| modify-log | `/dev log` |
| restart-volumn | `/dev restart` |
| restart-eval | `/dev eval` |
