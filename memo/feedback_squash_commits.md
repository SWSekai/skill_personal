---
name: 合併連續同目的 commits
description: 多個連續 commit 解決同一件事時，應 squash 成一個 commit 保持 history 乾淨
type: feedback
---

多個連續 commit 若都在解決同一件事，應合併（squash）成一個 commit。

**Why:** 保持 git history 乾淨、容易追蹤，避免瑣碎的修修補補佔滿 log。

**How to apply:** commit 前先檢查最近的 commit 是否在處理同樣的事，若是則用 `git rebase -i` 或 `--amend` 合併，而非新增一個重複目的的 commit。僅適用於尚未 push 的本地 commit。
