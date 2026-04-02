# create-skill — 建立新 Skill

## 功能說明

互動式建立全新的 Claude Code Skill，自動完成從定義到註冊的所有步驟。確保新 Skill 遵循既有結構規範，並同步更新所有索引文件。

## 使用方式

```
/create-skill [名稱] [描述...]
```

- 無參數：進入互動式問答，逐步收集資訊
- 帶參數：自動解析已知欄位，僅詢問缺少的部分

## 觸發條件

手動呼叫。當需要建立新的自動化指令時使用。

## 執行流程

1. **收集定義** — 名稱、指令、描述、觸發方式、工具清單、執行步驟
2. **名稱衝突檢查** — 確認 `.claude/skills/` 和 `skill_personal/` 無同名
3. **生成 SKILL.md** — 按 frontmatter + 步驟格式建立定義檔
4. **生成 README.md** — 建立功能說明文件
5. **更新索引** — `.claude/skills/README.md` 表格 + 說明 + 樹狀圖
6. **更新 CLAUDE.md** — Available Skills 清單
7. **同步 skill_personal** — 通用 Skill 自動複製、更新 manifest.json、commit + push
8. **完整性驗證** — 逐項確認所有檔案與索引一致
9. **輸出摘要** — 列出建立結果與更新的檔案

## 參數

| 參數 | 必填 | 說明 |
|------|:----:|------|
| 名稱 | - | Skill 名稱（kebab-case），未提供則互動詢問 |
| 描述 | - | 一行中文描述，未提供則互動詢問 |

## 設計原則

- 遵循 CLAUDE.md Rule 10（Skill 完整性檢查）
- 區分「通用」與「專案專屬」Skill，決定是否同步 skill_personal
- 所有 Skill 檔案不進入專案版控
