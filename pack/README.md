# Pack Skill

專案打包工具 — 收集 AI 上下文、保存專案專屬 skill、清除 skill 環境。

## 使用方式

```
/pack
```

## 打包產出

```
.local/ai-context/
├── CLAUDE.md              ← 專案規範快照
├── skills/                ← 全部 skill 快照
├── project-skills/        ← 專案專屬 skill（僅存在於 .claude/skills/ 的）
├── memory/                ← Memory 檔案
├── docs/                  ← 工作文件
├── logs/                  ← 修改日誌
├── summary/               ← 摘要
├── reports/               ← 報告
├── settings.local.json    ← Claude 本地設定
└── manifest.txt           ← 打包資訊與還原指引
```

## 腳本位置

`skill_personal/setup/sp-pack.sh`
