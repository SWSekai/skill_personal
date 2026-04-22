# Sekai-workflow

**[Claude Code](https://claude.com/claude-code) 向けの持ち運び可能なワークフローパック — どのプロジェクトに入れても、AI アシスタントが計画・実装・コミット・引き継ぎの作法を即座に把握できます。**

[English](./README.md) · [繁體中文](./README.zh-TW.md) · **日本語**

---

## これは何？

Sekai-workflow は Claude Code のための **Skills**（スラッシュコマンド）とフックのセットです。計画 → 実装 → テスト → 品質レビュー → commit/push → セッション間の引き継ぎまで、エンジニアリングワークフロー全体をパッケージ化しています。

**プロジェクト非依存に設計**：サービス名もハードコードされたパスも業務ロジックも含まれません。ワンコマンドのインストールで、どのリポジトリでも一貫した AI 協業が手に入ります。

> Claude Code との協業方法に対する `eslint + prettier + Conventional Commits + チームスタイルガイド` だと考えてください。

## なぜ使うのか？

AI コーディングアシスタントを複数プロジェクトで使っていると、同じ悩みが何度も出ます：

- 🔁 **毎回ルールを説明し直す**（Conventional Commits を使って／自動生成ファイルは触らないで／変更ログのフォーマットは⋯）
- 🧩 **セッション間で context が失われる** — 長い対話が圧縮されて、決めたことの半分が忘れ去られる
- 🏗️ **各自バラバラのワークフロー** — 開発者ごとに Claude の回し方が違い、チームの成果物がまちまちに
- 🧹 **後片付けが省略される** — 品質チェック、冗長コード掃除、変更ログ、コンテナ再起動の判定が忙しいと飛ばされる

Sekai-workflow は**再利用可能なスラッシュコマンド群**と**ガードフック**でこれらを自動化します。

## 機能一覧

9 つのコマンド入口（すべて `/command` で呼び出し）：

| コマンド | 用途 | 典型的なタイミング |
|---|---|---|
| `/hello` | 会話初期化 — 更新取得・先行 context 復元・ステータス概観 | 各セッション開始時 |
| `/build <all\|plan\|do\|test\|check\|review\|deploy>` | 開発全工程：分析 → 設計 → 実装 → テスト → 品質 → レビュー → デプロイ | 実装を始める前 |
| `/commit-push [msg]` | メインの commit 入口 — 品質チェック → 変更ログ → README 更新 → commit → push → デプロイ判定 → context 掃除 | 一区切り付いたとき |
| `/team <todo\|board\|decide\|note\|handoff\|report\|living\|follow-up>` | 人間×AI の協業：TODO、ホワイトボード、Markdown 意思決定表、技術メモ、引き継ぎ資料 | 計画・意思決定の場面 |
| `/ask <info\|trace>` | コードベースに関する質問、フィールドをスタック越しに追跡 | 「この値どう流れてる？」系 |
| `/skill <new\|sync\|pack>` | Skill 環境自体の管理 — 作成・上流同期・引き継ぎパッキング | Skill メンテ |
| `/clean [check\|force]` | Context ウィンドウの整理 — 要約・アーカイブ・`/clear`・自動復元 | チャットが長くなってきたら |
| `/memo` | フィードバック／好みメモをプロジェクト間で持ち運び | 新リポに入るとき |
| `/dispatch <task>` | Model 階層（Opus / Sonnet / Haiku）に応じて Agent 経由でタスクを振り分け | 明示的に model を切り替えたい時 |

## クイックスタート

### 前提

- [Claude Code CLI](https://claude.com/claude-code) がインストール・認証済み
- Git
- プロジェクトディレクトリ（新規でも既存でも）— 空フォルダでも OK

### インストール（30 秒）

```bash
# 1. プロジェクトの外（またはお好みの場所）に sekai-workflow を clone
git clone https://github.com/SWSekai/sekai-workflow.git

# 2. 自分のプロジェクトのルートで bootstrap を実行
#    Windows:
C:\path\to\sekai-workflow\_bootstrap\sp-init.bat

#    macOS / Linux / WSL（対応予定 — 現時点では Wine 経由で sp-init.bat を実行するか、
#    docs/QUICKSTART.md の手動手順を参照）
```

Bootstrap が自動で行うこと：

1. `.claude/skills/` を作成し、全 Skill をコピー
2. ローカル `Sekai_workflow/` を作成（初回実行後 `.sekai-workflow/` にリネーム）— 上流リポの更新を追跡
3. Claude Code 用にチューニングされた `CLAUDE.md` を生成
4. `pre-commit` フックを入れて、Skill ファイルが誤ってコミットされないようにガード
5. `.gitignore` に AI 関連の全ファイルを除外設定

これらすべてプロジェクトのバージョン管理の外で動きます — **自分のリポには自分のコードだけが commit されます。**

### 検証

```bash
# 保護レイヤーが揃っているかチェック
C:\path\to\sekai-workflow\_bootstrap\sp-verify.bat C:\your\project
```

## はじめてのワークフロー

インストール後、プロジェクト内で Claude Code を開き、順に試してみてください：

```
/hello          # Context 復元 + 上流更新チェック
/build plan     # 機能を説明 → 構造化された計画（Opus）
/build do       # Claude がステップごとに実装、完了項目を自動チェック
/commit-push    # 品質スキャン → 変更ログ → README 調整 → commit → push
/clean          # 会話が長くなったら：要約・アーカイブ・/clear
```

これが内側ループ全部です。各コマンドの `SKILL.md` と `README.md` は対応するフォルダにあり、Claude が自動で読み込むので構文を覚える必要はありません。

## 仕組み

3 層構造、単一のソース：

```
┌──────────────────────────────────────────────────────────┐
│  github.com/SWSekai/sekai-workflow   （このリポ）        │  ← 上流テンプレート
└─────────────────────────┬────────────────────────────────┘
                          │ clone / /skill sync
                          ▼
┌──────────────────────────────────────────────────────────┐
│  <your-project>/.sekai-workflow/   （ローカル複製）      │  ← git 管理外
└─────────────────────────┬────────────────────────────────┘
                          │ sp-init.bat / /skill sync
                          ▼
┌──────────────────────────────────────────────────────────┐
│  <your-project>/.claude/skills/    （実稼働 Skill）      │  ← git 管理外
└──────────────────────────────────────────────────────────┘
```

- **上流の更新** — 誰かが Skill を改良したら `/hello` か `/skill sync` で自動取り込み
- **下流の逆流** — ローカルで改良 → 汎用性があれば `/skill sync` が上流への push を確認（明示オプトイン、既定はローカルのみ）
- **プロジェクト固有の改変**は `.claude/skills/` に留まり、上流には流れません

### バージョン管理境界

| パス | 所有者 | プロジェクト git に入る？ |
|---|---|:---:|
| 自分のコード | 自分のプロジェクト | ✅ |
| `.claude/skills/` | ローカル専用 | ❌ |
| `.sekai-workflow/` | この上流リポ | ❌ |
| `CLAUDE.md` | ローカル専用 | ❌ |
| `.local/`（ログ・要約・レポート） | ローカル作業ノート | ❌ |

Bootstrap が `.gitignore` を自動整備します。**AI ファイルに対して `git add -f` は絶対にしないでください** — pre-commit フックが止めます。

## カスタマイズ

どの Skill も編集可能です。`.claude/skills/<skill>/SKILL.md` を開いて調整：

- **パス** — 変更ログ・要約・意思決定表の保存先
- **サービス** — Docker コンテナ名、compose ファイルのパス、デプロイコマンド
- **言語** — commit メッセージ言語、UI テキストの好み
- **フロー** — ステップの増減、トリガー条件

ローカル編集は上流へは流れません。汎用的だと判断した場合、フラグを立てて `/skill sync` 経由で上流に貢献できます。

## ドキュメント

- [QUICKSTART](./docs/QUICKSTART.md) — シナリオ例付きの一通り
- [ファイル出力リファレンス](./docs/file-output-reference.md) — 各コマンドの成果物の保存先
- [`manifest.json`](./manifest.json) — 機械可読な Skill インデックス（model 階層・allowed tools 含む）
- 各 Skill 個別ドキュメントは対応フォルダ（`build/README.md`、`team/README.md` など）

## Model 三層

Skill は作業特性に応じて model 階層を割り当てます：

- **Opus** — 計画、品質レビュー、アーキテクチャ判断、深掘り分析
- **Sonnet** — 複数ステップの実行、ファイル編集、標準的な開発タスク
- **Haiku** — 構造化テキスト生成（変更ログ、ステータスチェック、テンプレート）

`/dispatch` は Agent 経由で**実際の** model 切り替えを行い、単一タスクで特定 model が必要な時に使います。全マッピングは [`references/model-routing.md`](./references/model-routing.md) 参照。

## コントリビュート

Issue と PR を歓迎します。メインリポは [github.com/SWSekai/sekai-workflow](https://github.com/SWSekai/sekai-workflow)。

Skill 変更を出す前に `/skill sync` を一度走らせ、最新の上流に対する diff を取ってください。

README 翻訳の貢献も歓迎 — `README.<lang>.md` をこのディレクトリに追加し、各 README 冒頭の言語切り替え行を更新してください。

## License

[LICENSE](./LICENSE) があればそちらに従います。無ければ、上流で明示されるまで全権保留扱いとしてください。

---

> **詳しい操作マニュアルをお探しですか？**以前この README に載っていた詳細は [docs/QUICKSTART.md](./docs/QUICKSTART.md) と各 Skill フォルダの `README.md` に移動しました。このページは初見の方向けに軽めに保っています。
