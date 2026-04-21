# Claude Code Agents

chezmoi で `~/.claude/agents/` にデプロイされる自作エージェントの一覧と運用メモ。

> この `README.md` は `.chezmoiignore` で Claude Code 側にデプロイされないように除外している（agent として誤認されないよう）。

## 一覧

| エージェント | 役割 | 呼ぶべきタイミング | 親から渡す主要情報 |
|---|---|---|---|
| [code-reviewer](code-reviewer.md) | コードレビュー（規約／テスト／パフォーマンス／アーキ／セキュリティ） | コード作成・修正後 | 対象ファイル、重点観点 |
| [doc-reviewer](doc-reviewer.md) | 技術ドキュメントのレビュー（正確性・構成・誤字脱字） | ドキュメント作成・更新後 | 対象ファイル、想定読者 |
| [system-design-reviewer](system-design-reviewer.md) | 設計書・RFC のレビュー（要件整合・非機能・代替案） | 設計ドキュメント作成後 | 設計書、要件定義書、規模感 |
| [marketing-reviewer](marketing-reviewer.md) | Web マーケ観点（KPI/CMP/SEO/CWV）のレビュー | 要件〜運用の各フェーズ | 対象、フェーズ、業態 |
| [agent-doc-reviewer](agent-doc-reviewer.md) | エージェント定義ファイルのメタレビュー | エージェント作成・更新後 | 対象エージェントのパス |
| [dev-cycle](dev-cycle.md) | 実装＋レビューのループを回すオーケストレータ | programmer と code-reviewer を反復委譲したい時 | タスク、対象ファイル、完了条件 |
| [programmer](programmer.md) | 実装タスクの実行 | オーケストレータから委譲／明示指定 | タスク、対象ファイル、完了条件 |
| [test-debugger](test-debugger.md) | 落ちたテストの原因切り分け（flaky 判定含む） | テストが落ちた／flaky で困っている | 落ちたテスト、エラーログ、環境 |
| [tutor](tutor.md) | 技術知識の学習支援（ソクラテス／クイズ／Feynman） | 学びたいとき／理解確認 | トピック、URL、PR、レベル目標 |

## 使い分けチャート

**何をしたい？ → どれ呼ぶ？**

- コード書いた／修正した → `code-reviewer`
- ドキュメント書いた → `doc-reviewer`
- 設計した／RFC 書いた → `system-design-reviewer`
- マーケ観点でのチェック → `marketing-reviewer`
- エージェント定義を書いた／直したい → `agent-doc-reviewer`
- 実装＋レビューのループを回したい → `dev-cycle`（programmer と code-reviewer を内部で呼ぶ）
- 単発の実装だけ委譲したい → `programmer`
- テストが落ちた／flaky 調査 → `test-debugger`
- 技術を学びたい／理解度チェック → `tutor`

## 共通設計パターン

自作エージェントは以下のパターンを踏襲する。

### frontmatter

```yaml
---
name: <kebab-case>
description: "<1行目: 役割の1〜2行要約>\n\n**起動時に親が渡すべき情報**:\n- ...\n\nExamples:\n- user: ...\n  assistant: ..."
model: sonnet        # デフォルト。重い推論が必要なら opus
color: <yellow/green/pink/purple/orange/...>
memory: user         # ユーザー横断で覚えたい場合のみ（現状 code-reviewer / tutor で使用中）
---
```

### 本文の定型構成

1. **役割・対象領域**（1〜2行の自己紹介）
2. **起動時の入力**（親から渡すべき情報のフォーマット）
3. **観点・手順・判定基準**（Before/After の `<example>` ブロックを積極活用）
4. **レポートフォーマット＋記入例**
5. **重要な原則**（箇条書きで短く）

### 重大度絵文字（レビュー系で統一）

| 絵文字 | 意味 |
|---|---|
| 🔴 | 重大（必ず対応推奨） |
| 🟡 | 改善推奨 |
| 🟢 | 軽微 |
| ⚠️ | 要確認（裏取りしきれなかった主張など） |
| ✅ | 特に優れた点 |

## 新しいエージェントを追加する手順

1. `dot_claude/agents/<name>.md` を作成（既存を雛形にする）
2. `chezmoi apply ~/.claude/agents/<name>.md` で反映
3. **新しいセッションで** `agent-doc-reviewer` に自己レビューさせる
   - 既存セッションだと agent 一覧がキャッシュされていて呼び出せない場合がある
   - その場合は `general-purpose` 経由で proxy するか、セッションを切り直す
4. 指摘を反映してコミット（修正単位ごとに分けると差分が追いやすい）

## 関連ファイル

- デプロイ先: `~/.claude/agents/<name>.md`
- chezmoi ソース: `dot_claude/agents/<name>.md`
- 除外設定: `.chezmoiignore`（この README を除外）
