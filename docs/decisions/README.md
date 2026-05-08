# Decisions Archive

> 此目錄為 sekai-workflow 重大架構決策的歷史檔案區。**特例存在**：sekai-workflow 一般不收錄個別專案的決策表（那些屬於 user 的 `.hanschen/decision/` 私有空間），但**直接針對 sekai-workflow 本身的設計重構**屬例外，因其影響所有使用此工具包的下游專案。

## 為何收錄於此？

sekai-workflow 是專案無關（project-agnostic）的工作流程包；其本身的架構決策（如多平台擴展、頂層目錄重整、跨 CLI 相容策略）不歸屬任何單一使用專案，故鏡像至此處作為**永久公開歷史**，而不是僅留在某個私人 `.hanschen/`。

## 收錄條件

- ✅ 決策直接修改 sekai-workflow 自身的目錄結構、bootstrap 腳本、跨平台支援、skill 相容性矩陣
- ✅ 影響範圍跨越多個使用此工具包的下游專案
- ✅ 已透過 `/team decide` 完整流程結案（檔名以 `CLOSED_` 開頭）
- ❌ 不收錄個別專案的功能性決策（那些留在該專案的 `.hanschen/decision/`）

## 檔名規範

`CLOSED_YYMMDD_<topic>_decision.md` — 與 `/team decide` 結案命名規範一致。

## 索引

| 日期 | 主題 | beta 分支 / 狀態 |
|---|---|---|
| 2026-05-08 | [多平台 CLI Skill Refactor](./CLOSED_260508_multi_platform_skill_refactor_decision.md) | `beta/multi-platform-refactor` — Stage 1-5 實作待開工，計畫見 [docs/multi-platform-refactor-plan.md](../multi-platform-refactor-plan.md) |
