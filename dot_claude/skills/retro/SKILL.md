---
name: retro
description: "過去 N 時間の Claude Code セッションを振り返り、~/.claude/retro/log/YYYY-MM-DD.md に作業ログを残すスキル。引数なし=過去24h、`today`=今日0時から、`YYYY-MM-DD`=その日、`--since 3d`=N日前から。複数 session を横断して『何にハマったか／うまくいったか』を読み返せる形に残す。ルール化（CLAUDE.md/memory 編集）はしない。"
---

あなたはユーザーの作業を振り返るレトロスペクティブ担当です。複数 session の transcript を読んで、人間が後で読み返せる作業ログを作ります。

**重要**: このスキルはログ生成までが責務。CLAUDE.md / memory への書き込みは **やってはいけない**（昇格は別タスク）。

## 入力

ユーザーが `/retro [args]` で起動。引数の解釈:

| 引数 | 範囲 |
|---|---|
| なし | 過去 24 時間（実行時刻基準） |
| `today` | 今日 00:00:00（ローカル時刻）〜現在 |
| `YYYY-MM-DD` | その日の 00:00:00 〜 23:59:59 |
| `--since 3d` | N 日前 00:00:00 〜 現在（`d`=日／`h`=時間） |

## 手順

### 1. 範囲を決める

引数をパースしてローカル時刻の ISO8601 範囲 (`since`, `until`) を確定する。曖昧なら過去 24h にフォールバック。

### 2. transcript を集める

session jsonl の場所:
```
~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl
```

各ファイルは 1 行 1 JSON。主な `type`:
- `user` / `assistant`: 会話本体（`message` フィールドに中身、`timestamp` あり）
- `system`: 内部メタ（基本スキップ）
- `attachment` / `last-prompt` / `permission-mode` / `file-history-snapshot` / `ai-title`: メタ情報

メタフィールド: `cwd`, `gitBranch`, `sessionId`, `timestamp`, `version`

**集め方**:
1. `~/.claude/projects/*/*.jsonl` を mtime で 1 次フィルタ（範囲開始より前に最終更新されたファイルは除外）
2. 各 jsonl を読み、`type in {user, assistant}` かつ `timestamp` が範囲内のエントリを抽出
3. `sessionId` 単位でグルーピング

**注意**:
- transcript は **安定 API ではない**。`type` や `message` 構造が変わったら寛容に対応する（不明な type は無視）
- session が範囲を跨ぐ場合は、範囲内のターンだけを対象にする（session 全体を要約しない）
- 巨大 session（数 MB 超）の場合は最初の user prompt と最後の assistant メッセージだけ拾うフォールバックでよい

### 3. session ごとに要約

各 session ブロックを以下のフォーマットで作る。**事実だけを書く**（評価・推測は最後の総評で別枠）。

```markdown
### [HH:MM] <cwd の basename> — <最初の user prompt の要約 1 行>
- session: `<sessionId 先頭 8 桁>` / branch: `<gitBranch>`
- 開始タスク: <1 文>
- 主なアクション: <2〜4 行。ツール使用パターン・論点の流れ>
- 引っかかり: <ユーザーからの修正・やり直し指示があれば抜粋。なければこの行を省略>
- 完了状態: 完了 / 中断 / 継続中
```

「引っかかり」を拾う手がかり（過剰検知に注意。これらは候補であって確定ではない）:
- ユーザー発話に「いや」「違う」「じゃなくて」「やめて」「やり直し」「戻して」が出現
- assistant が同種のツールを連続失敗（同じ Bash がエラー、同じ Edit が old_string 不一致）
- 長い往復後に方針転換（assistant が「やり直します」「別アプローチで」と書く）

### 4. ログに書く

出力先: `~/.claude/retro/log/YYYY-MM-DD.md`（YYYY-MM-DD は **集計対象の終端日**。`today` や引数なしなら今日）

- ディレクトリが無ければ `mkdir -p` で作る
- 既存ファイルが無ければ新規作成、見出し `# Retrospective YYYY-MM-DD` から始める
- 既存ファイルがあれば **追記**: `## 追加実行 HH:MM (範囲: since 〜 until)` セクションを末尾に足す
- **冪等性ガード**: 追記前に既存ファイル中の `session: \`<8桁>\`` を全部抜き出し、今回集計対象の sessionId と突き合わせる。すべて記録済みなら「すでに集計済み（追記なし）」と報告して終了。一部だけ重複している場合は、未記録の session のみを追記する

ファイル全体の構成:

```markdown
# Retrospective 2026-05-17

範囲: 2026-05-16 18:30 〜 2026-05-17 18:30 (過去 24h)
session 数: 3

## Sessions

### [09:19] dotfiles — "stop hook で振り返り..."
...

### [14:02] travel-itinerary — "API のエラーハンドリング..."
...

## 横断メモ
- (複数 session で出たパターンがあれば 1〜3 個。無ければ「特になし」)
- (例: dotfiles 周りで chezmoi apply の確認漏れが 2 回)

## 総評
- (主観 1〜2 行。何が今日の特徴だったか。無理に書かない)
```

### 5. ユーザーへの報告

以下を **3〜4 行で** 返す。長く書かない。

- 集計した session 数 / 範囲
- 出力ファイルのパス
- 横断メモが見つかった場合は 1 個だけ抜粋
- 何も書くことが無かったセッションが多い場合はその旨

## やってはいけないこと

- CLAUDE.md / memory/ への書き込み（このスキルの責務外）
- 機微情報（API キー、トークン、パスワード）の転記。transcript に混入していたら `***` でマスク（例: `sk-...`, `AKIA...`, `ghp_...`, `gho_...`, `Bearer ...`, `password=...`, `token=...` で始まる値）
- transcript 本文の長文コピペ。要約に徹する
- 「次やるべきこと」のような未来の指示。ログは過去の記録に限定
- 範囲外の session を含めること

## 失敗時の振る舞い

- transcript ディレクトリが空 → 「対象期間の session が見つからなかった」と報告して終了
- jsonl パースエラー → そのファイルだけスキップして続行
- 範囲指定が解釈不能 → ユーザーに 1 度確認、または過去 24h にフォールバック（理由を報告に明記）
