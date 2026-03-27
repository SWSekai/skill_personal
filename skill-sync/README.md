# skill-sync — Skill 環境初始化、遠端同步、規則評估

## 功能概述

自動確保 Skill 環境就緒並保持同步的核心 Skill，包含三大功能：

1. **新專案自動初始化** — 偵測缺少 `.claude/skills/` 的專案，自動從模板建立並生成 CLAUDE.md
2. **skill_personal 遠端同步** — 每次對話開始時檢查本地與遠端差異，自動 pull → 揉合 → push
3. **規則評估與歸類** — 新增至 CLAUDE.md 或 Memory 的規則，自動評估是否應納入 Skill 或 skill_personal

## 觸發方式

| 時機 | 觸發方式 |
|---|---|
| 對話開始 | 自動觸發（檢查環境 + 遠端同步） |
| 新增規則至 CLAUDE.md / Memory | 自動觸發（規則評估） |
| 修改 skill_personal/ | 自動觸發（同步至 skill_personal 遠端） |
| 使用者呼叫 `/skill-sync` | 手動觸發（完整流程） |

## 執行流程

```
對話開始
  │
  ├─ .claude/skills/ 存在？
  │   ├─ 否 → 流程一：自動初始化
  │   └─ 是 → 繼續
  │
  ├─ skill_personal/ 為 git repo？
  │   ├─ 否 → git init + remote add
  │   └─ 是 → 流程二：遠端同步
  │
  └─ 完成

新增規則
  │
  └─ 流程三：規則評估
      ├─ 僅限本專案 → CLAUDE.md / Memory
      └─ 通用規則 → 更新 Skill → 回流 skill_personal/ → 推送至遠端
```

## 目錄結構

```
skill-sync/
├── README.md      ← 本文件
└── SKILL.md       ← Skill 定義與完整流程
```
