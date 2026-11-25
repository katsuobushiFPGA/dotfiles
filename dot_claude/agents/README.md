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
| [agent-prompt-tuner](agent-prompt-tuner.md) | エージェント定義ファイルのメタレビュー（軽微指摘は自動修正） | エージェント作成・更新後 | 対象エージェントのパス |
| [dev-cycle](dev-cycle.md) | 実装＋レビューのループを回すオーケストレータ | programmer と code-reviewer を反復委譲したい時 | タスク、対象ファイル、完了条件 |
| [programmer](programmer.md) | 実装タスクの実行 | オーケストレータから委譲／明示指定 | タスク、対象ファイル、完了条件 |
| [test-debugger](test-debugger.md) | 落ちたテストの原因切り分け（flaky 判定含む） | テストが落ちた／flaky で困っている | 落ちたテスト、エラーログ、環境 |
| [tutor](tutor.md) | 技術知識の学習支援（ソクラテス／クイズ／Feynman） | 学びたいとき／理解確認 | トピック、URL、PR、レベル目標 |
| [quiz-master](quiz-master.md) | 技術知識をクイズで叩いて定着させる出題マシン（即採点・即解説） | 既知知識のテスト／隙間時間で叩く | トピック、URL、PR、難易度、問題数 |
| [mock-interviewer](mock-interviewer.md) | 技術面接官ロールで言語化を強制し説明力を鍛える（4 モード／1 問ごと即フィードバック） | 面接練習／説明力鍛錬／知識定着の最終確認 | モード、トピック、難易度、時間目安 |

## 使い分けチャート

**何をしたい？ → どれ呼ぶ？**

- コード書いた／修正した → `code-reviewer`
- ドキュメント書いた → `doc-reviewer`
- 設計した／RFC 書いた → `system-design-reviewer`
- マーケ観点でのチェック → `marketing-reviewer`
- エージェント定義を書いた／直したい → `agent-prompt-tuner`
- 実装＋レビューのループを回したい → `dev-cycle`（programmer と code-reviewer を内部で呼ぶ）
- 単発の実装だけ委譲したい → `programmer`
- テストが落ちた／flaky 調査 → `test-debugger`
- 技術を学びたい／理解度チェック → `tutor`
- 既知の知識をクイズで叩きたい／テストされたい → `quiz-master`
- 面接練習したい／説明できるか試されたい → `mock-interviewer`

## 共通設計パターン

自作エージェントは以下のパターンを踏襲する。現行モデル（Fable 5.2 / Opus 5.5）向けの書き方で、根拠は Anthropic 公式の [Subagents](https://code.claude.com/docs/en/sub-agents)、[Model configuration](https://code.claude.com/docs/en/model-config)、[Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) にある。

### frontmatter

```yaml
---
name: <kebab-case>
description: "<何をするか>。<いつ使うか>。親は<必須の入力>を渡す。"
model: opus          # opus / fable / sonnet / haiku / inherit、またはフル ID
effort: medium       # low / medium / high / xhigh / max
color: <red/blue/green/yellow/purple/orange/pink/cyan>
memory: user         # ユーザー横断で覚えたい場合のみ（code-reviewer / tutor / quiz-master / mock-interviewer で使用中）
---
```

- `description` は全エージェント分が常にコンテキストに載るので 2〜3 文に収める。対話例や任意項目の一覧は本文に書く。
- `model` を書いたら `effort` も書く。メインの会話と違うモデルで動くサブエージェントには、セッションの effort（`settings.json` の `effortLevel`）が引き継がれない。
- Claude Code は未知のフィールド名や値をエラーにせず無視する。`scripts/check-agent-frontmatter dot_claude/agents` で検証できる（`scripts/check` からも実行される）。

モデルと effort の割り当て:

| model | effort | エージェント | 考え方 |
|---|---|---|---|
| `fable` | `high` | dev-cycle, system-design-reviewer, test-debugger | オーケストレーション、アーキテクチャ判断、根本原因の調査。曖昧さが大きい作業 |
| `opus` | `high` | code-reviewer, marketing-reviewer | 既存コードの不具合検出、法規制や一次情報の裏取り |
| `opus` | `medium` | programmer, doc-reviewer, agent-prompt-tuner, tutor, quiz-master, mock-interviewer | 範囲の決まった実装、文書のレビュー、対話 |

Fable は Opus の 2 倍の単価で、プランによっては含まれる上限とは別に課金される。迷ったら `opus` にする。

### 本文の書き方

- 冒頭の 1〜2 文で役割と読み手を述べる。
- 手順ではなく、達成したい結果と判断基準を書く。番号付きの手順は、順序に理由があるときだけ使い、理由を添える。
- 規則には適用範囲と理由を添える。「必ず」「禁止」や太字での強調は、モデルが例外なく適用して想定外の場面でも発動するので使わない。
- 「よく考えて」「再確認する」のような推論や検証の念押しは書かない。考える深さは `effort` で決める。
- 記入例は `<example>` で 3〜5 個、判断が分かれるケースを選ぶ。
- 親が渡す入力（必須か任意か、未指定のときの扱い）と、レポートの見出しを定義する。レポートは、親がそれだけを読んで次の行動を決められるように書かせる。
- 反復には上限と、上限に達したときの振る舞いを書く。

### 重大度絵文字（レビュー系で統一）

| 絵文字 | 意味 |
|---|---|
| 🔴 | 重大（対応が必要。CLAUDE.md のレビューループと dev-cycle は 🔴 の有無で次の行動を決める） |
| 🟡 | 改善推奨 |
| 🟢 | 軽微 |
| ⚠️ | 要確認（裏取りしきれなかった主張など） |
| ✅ | 特に優れた点 |

## 新しいエージェントを追加する手順

1. `dot_claude/agents/<name>.md` を作成（既存を雛形にする）
2. `scripts/check-agent-frontmatter dot_claude/agents` で frontmatter を検証し、`chezmoi apply ~/.claude/agents/<name>.md` で反映
3. **新しいセッションで** `agent-prompt-tuner` に自己レビューさせる
   - 既存セッションだと agent 一覧がキャッシュされていて呼び出せない場合がある
   - その場合は `general-purpose` 経由で proxy するか、セッションを切り直す
4. 指摘を反映してコミット（修正単位ごとに分けると差分が追いやすい）

## 関連ファイル

- デプロイ先: `~/.claude/agents/<name>.md`
- chezmoi ソース: `dot_claude/agents/<name>.md`
- 除外設定: `.chezmoiignore`（この README を除外）
- 削除設定: `.chezmoiremove`（改名・削除したエージェントのデプロイ済みファイルを消す。エージェントを改名・削除したら旧パスを追記する）
