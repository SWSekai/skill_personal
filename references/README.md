# References

跨專案技術參考文件，隨 `skill_personal` git repo 同步到所有專案。與 Skill 不同：Skill 是可執行流程（`/` 命令），references 是純知識文件，供 Claude 遇到相關問題時查閱。

## 目錄

| 檔案 | 內容 |
|---|---|
| [model-routing.md](./model-routing.md) | Skill `model` frontmatter 選擇規則（opus / sonnet / haiku），含完整分配表與 effort 對照 |
| [askuserquestion-tool.md](./askuserquestion-tool.md) | `AskUserQuestion` deferred tool 完整使用手冊：載入流程、參數 schema、設計規則、範例 |

## 新增規範

- 參考文件命名：`kebab-case.md`（例：`model-routing.md`）
- 檔案開頭註明最後更新日期（`> 最後更新：YYYY-MM-DD`）
- 新增 / 修改後請於此 README 同步更新索引
- 若內容屬於「某 Skill 專用參考」，改放在該 Skill 目錄下的 `references/`（例：`commit-push/references/`），不放此處
- 若內容是「行為偏好 / 禁止事項」，放 `memo/feedback_*.md` 而非 references/
