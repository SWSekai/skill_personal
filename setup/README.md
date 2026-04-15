# setup — Skill 環境管理

## 功能說明

整合建立新 Skill、遠端同步與規則評估、專案打包三項職能。

## 使用方式

```
/setup <new|sync|pack> [args...]
```

## Model

- **建議 model**: `sonnet`
- **Effort**: `medium`
- **理由**: 多檔生成 + 索引註冊 + Git 同步，需要判斷力

## 觸發條件

- `new`：手動呼叫
- `sync`：對話開始自動 / 手動
- `pack`：手動呼叫

## 執行流程

| 子命令 | 用途 |
|---|---|
| `new [name] [desc]` | 建立新 Skill（互動式定義 → 檔案生成 → 索引更新 → 同步） |
| `sync` | Sekai_workflow 遠端同步、規則評估與三向連動 |
| `pack` | 專案打包並清除 skill 環境 |

## 目錄結構

```
setup/
├── SKILL.md
├── README.md
├── references/
│   ├── model-selection-guide.md          ← Model 選擇決策樹
│   ├── evaluation-decision-tree.md       ← 規則評估歸類決策樹
│   └── version-control-boundaries.md     ← 版控邊界說明
└── assets/
    ├── SKILL.md.template                 ← 新 Skill 的 SKILL.md 模板
    └── README.md.template                ← 新 Skill 的 README.md 模板
```

## 整合來源

| 原 Skill | 對應子命令 |
|---|---|
| create-skill | `new` |
| skill-sync | `sync` |
| pack | `pack` |
