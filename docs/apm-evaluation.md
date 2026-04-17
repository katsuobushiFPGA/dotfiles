# APM（Agent Package Manager）調査メモ

調査日: 2026-04-17

## 概要

Microsoft がオープンソース（MIT）で開発しているツール。
AIエージェントの設定を `apm.yml` に一元管理し、チーム全員が同じエージェント環境を再現できるようにする。
npm や pip のエージェント版。

- リポジトリ: https://github.com/microsoft/apm
- ドキュメント: https://microsoft.github.io/apm/
- インストール: macOS / Linux / Windows 対応（Scoop, pip, バイナリ直接）

## 管理できる 7 つのプリミティブ

| プリミティブ | 説明 |
|---|---|
| Instructions | CLAUDE.md / AGENTS.md にコンパイルされるルール |
| Skills | スキル（`.claude/skills/` 等にデプロイ） |
| Prompts | 再利用可能なプロンプト |
| Agents | エージェント定義 |
| Hooks | フック定義 |
| Plugins | プラグイン |
| MCP Servers | MCP サーバー設定 |

## 主なコマンド

- `apm install` — `apm.yml` をもとに `.claude/`, `.github/`, `.cursor/`, `.opencode/` にデプロイ。推移的依存解決あり
- `apm compile` — instructions を `CLAUDE.md`（Claude用）や `AGENTS.md`（Copilot/Cursor/Codex用）にまとめて出力
- `apm audit` — Unicode の隠し文字など、セキュリティチェック

## 対応ツール

Claude Code, GitHub Copilot, Cursor, OpenCode, Codex を一つの `apm.yml` から管理。

## 現状の構成（`npx skills` + chezmoi）との比較

| 観点 | 現状（`npx skills`） | APM |
|---|---|---|
| スキル管理 | `.skill-lock.json` + chezmoi | `apm.yml` + `apm install` |
| 依存解決 | なし（フラット） | 推移的依存解決あり |
| 対象ツール | Claude Code のみ | Claude Code, Copilot, Cursor 等 |
| instructions 管理 | 手動で CLAUDE.md 編集 | `apm compile` で自動生成 |
| hooks/MCP 管理 | settings.json で手動 | `apm.yml` に宣言的に書ける |
| セキュリティ | なし | `apm audit` あり |
| 配布 | GitHub リポジトリ直接 | GitHub リポジトリ + マーケットプレイス |

## 導入メリットがありそうなケース

- 複数の AI ツールを併用している（Copilot + Claude Code 等） → 設定の一元管理が効く
- チーム開発で全員のエージェント環境を揃えたい → `apm.yml` をリポジトリにコミットするだけ
- スキルの依存関係が複雑になってきた → 推移的依存解決が便利

## 現状のままでよさそうなケース

- 個人の dotfiles 管理が主目的 → chezmoi + `npx skills` で十分
- Claude Code しか使っていない → マルチツール対応のメリットが薄い
- CLAUDE.md を自分で細かくコントロールしたい → `apm compile` の自動生成と手書きの共存に注意が必要

## 検討ポイント（TODO）

- [ ] `apm compile` で生成される CLAUDE.md と手書き部分の共存方法を確認
- [ ] `npx skills` で管理している既存スキルの移行コストを見積もる
- [ ] chezmoi との共存（dotfiles 管理との二重管理にならないか）
- [ ] `apm.yml` の依存先として自作スキル（`dot_claude/skills/*.md`）をどう扱うか
