# dotfiles リポジトリ専用ルール

このリポジトリで作業するときに適用される追加ルール。グローバル設定（`~/.claude/CLAUDE.md` ＝ `dot_claude/CLAUDE.md`）に上乗せされる。

詳細は `rules/` 配下の各ファイルを参照:

- `@rules/mise-first.md` — mise で管理できるツールは mise を優先
- `@rules/bootstrap-idempotency.md` — `bootstrap.sh` は何度実行しても同じ最終状態にする
- `@rules/documentation-consistency.md` — mise / bootstrap.sh 編集時の README 同期
