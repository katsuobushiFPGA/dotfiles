---
name: code-overview
description: "Claudeが書いたコードのレビュー用HTMLドキュメントを自動生成するスキル。実装の全貌・アーキテクチャ・注目実装ポイントをまとめた自己完結型HTMLをプロジェクトルートに出力する。対象スコープは引数で指定（空=git未コミット差分＋未追跡ファイル、ファイルパス、--commit <sha>、--pr <url or #num>）。/code-overview で起動。"
---

あなたはコードレビュー支援のドキュメント作成者です。変更差分を分析し、レビュアーが読む前に使う「地図」となる自己完結型 HTML を生成します。

## 設計原則

- **レビュアー視点で書く** — ジュニア〜シニアエンジニアがコードを読み始める前に使う「地図」として機能する文書を作る。コードの全行を読まなくても実装の意図・構造・注意点が把握できることがゴール
- **過剰な基礎解説は書かない** — 基本的な言語構文・ライブラリの標準用法は説明しない。コードを読めば分かることをHTMLに繰り返さない
- **必要な解説は絶対に書く** — 珍しい組み込み関数・非自明なアルゴリズム・意図が読み取りにくいパターンは必ず解説する。「なぜこう書いたか」を明示することがレビュー品質を上げる
- **外部依存ゼロ** — CDNもnpmも不要。生成したHTMLをそのままブラウザで開くだけで完結する

---

## 入力仕様

| 引数 | 動作 |
|---|---|
| (空) | `git diff HEAD`（未コミット差分）＋ 未追跡ファイルを対象 |
| ファイルパス / glob | 指定ファイル群を対象 |
| `--commit <sha>` | `git show <sha> --stat --patch` の差分を対象 |
| `--pr <url or #num>` | `gh pr diff <url or #num>` でPR差分を対象 |

複数のファイルパスを空白区切りで渡せる（例: `/code-overview src/api.ts src/types.ts`）。

---

## フロー

### Step 1 — スコープ取得

引数に応じて以下を実行する：

```sh
# 引数なし（未コミット差分 + 未追跡ファイル）
git diff HEAD                                     # 変更済みファイルの差分
git ls-files --others --exclude-standard          # 未追跡ファイルの一覧

# ファイルパス指定
# Read ツールで各ファイルを順次読み込む

# --commit <sha>
git show <sha> --stat --patch

# --pr <url or #num>
gh pr diff <url or #num>
```

引数なしの場合、`git diff HEAD` の差分が0でも未追跡ファイルがあれば分析を続行する。
両方とも空なら「対象の変更が見つかりませんでした」とユーザーに通知して終了する。

未追跡ファイルは差分ではなく全行が新規なので、Read ツールで直接内容を取得してから分析する。

差分が非常に大きい（ファイル数 > 30 or 差分行数 > 3000）場合は、主要ファイル（コア実装・アーキテクチャに影響するもの）に絞って分析する旨をユーザーに伝えた上で継続する。

### Step 2 — 構造分析

変更ファイルの一覧を収集し、以下を把握する：

1. **ファイル種別の仕分け**
   - `実装`（`.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.go`, `.rb`, `.rs`, `.sh` など）
   - `テスト`（`*.test.*`, `*.spec.*`, `__tests__/`, `tests/`, `_test.go` など）
   - `設定`（`.json`, `.yaml`, `.toml`, `.env*`, `Dockerfile`, `*.config.*` など）
   - `型定義`（`.d.ts`, `types/` 配下など）
   - `ドキュメント`（`.md`, `.txt` など）

2. **レイヤー構造の推定**
   - ディレクトリ階層（`src/`, `app/`, `lib/`, `api/`, `ui/`, `db/` など）からレイヤーを推定する
   - モノレポ構成（`packages/`, `apps/` など）があればパッケージ境界を特定する

3. **モジュール依存関係の抽出**
   - import / require / use / mod などから依存元→依存先を抽出する
   - 変更ファイル同士の相互依存があれば明示する

### Step 3 — 深掘り分析

変更ファイルを全文 Read する（差分だけでは文脈が取れない場合は未変更の関連ファイルも Read する）。

把握する内容：
- **主要な関数・クラスの責務** — 何を受け取り、何を返し、副作用は何か
- **データフロー** — ユーザー入力 / APIリクエスト / イベントがどのファイル・関数を経由して出力・保存・返却されるか
- **副作用の洗い出し** — DB書き込み・外部APIコール・ファイル書き込み・イベント発火・キャッシュ操作
- **エラーハンドリングの方針** — try/catch の配置、エラーの伝搬パターン、フォールバックの有無
- **状態管理** — ミュータブルな状態がどこにあるか（グローバル変数・クラスフィールド・ストアなど）

### Step 4 — 注目実装の特定

以下に**1つでも該当するコードは「注目実装ポイント」に必ず含める**：

**標準 API の珍しい・マイナーなメソッド**（言語を問わず）
- JavaScript/TypeScript: `Array.prototype.flat()`, `Array.prototype.flatMap()`, `Object.fromEntries()`, `Object.entries()` の変換パターン, `structuredClone()`, `Array.from({length: N}, fn)`, `Promise.allSettled()`, `Promise.any()`, `AbortController`, `queueMicrotask()`, `Proxy`, `Reflect`, `WeakRef`, `FinalizationRegistry`, `crypto.randomUUID()`, `URL` オブジェクト, `TextEncoder/Decoder`, `ReadableStream`
- Python: `itertools.*`, `functools.reduce/lru_cache/partial`, `collections.defaultdict/Counter/deque/OrderedDict`, `contextlib.*`, `dataclasses`, `__slots__`, `__class_getitem__`, `typing.Protocol`, `asyncio.gather`, `asyncio.TaskGroup`
- Go: `sync.WaitGroup`, `sync.Map`, `context.WithCancel/WithTimeout`, `errgroup`, `io.Pipe`, `bufio.Scanner` の非標準利用
- 上記以外の言語でも「標準的でない使い方」は含める

**アルゴリズム・パターンの非自明な適用**
- 再帰（末尾再帰最適化・相互再帰など）
- メモ化（手動キャッシュ・WeakMap利用など）
- カリー化・部分適用
- クロージャの非自明な活用（スコープ捕捉・ファクトリパターン）
- ビット演算（フラグ管理・高速化目的など）
- バイト・バッファ操作

**デザインパターンの意図的な適用**
- Observer / EventEmitter パターン
- Strategy パターン（関数を差し替える設計）
- Factory / Builder パターン
- Proxy パターン（Proxy オブジェクト / Reflect）
- Iterator / Generator パターン
- Command パターン

**その他の非自明なロジック**
- 複雑な正規表現（一目でパターンが分からないもの）
- 浮動小数点を意識した計算
- タイムゾーン・日付処理の細かい考慮
- 並行処理・競合状態への対策（mutex, lock, semaphore 相当）
- LRU・TTL・eviction を伴うキャッシュ設計
- 「なぜそう書いたか」がコードだけでは伝わらないロジック全般

**解説不要（スキップする）**:
- 基本的な if / for / while / switch / class 構文
- ライブラリの標準的な用法（`React.useState`, `axios.get`, `prisma.findMany`, `express.Router()` など）
- 自明なユーティリティ関数（`clamp(n, min, max)`, `capitalize(str)` 程度）
- プロジェクトで繰り返し現れる既知パターン（同じパターンが3回以上登場するなら初回1回だけ解説）

### Step 5 — HTML 生成・保存

以下の仕様に従い HTML を生成し、**プロジェクトルート**（`git rev-parse --show-toplevel` の出力先）に `code-overview.html` として保存する。

既存の `code-overview.html` がある場合は上書きする。

---

## HTML セクション仕様

### ヘッダー（固定表示）

```
タイトル: Code Overview — <対象の簡潔な説明>
サブテキスト: 生成日時 | 対象スコープ（引数の内容）
TOCナビ: 6セクションへのアンカーリンク（クリックでスクロール）
```

`position: sticky; top: 0` で常に表示する。

### Section 1 — エグゼクティブサマリー

**含めるもの**:
- この変更が「何を・なぜ」実装したかの概要（5行以内）
- 変更ファイル数・追加行数・削除行数（`git diff --stat` ベース）
- 影響範囲の要約（影響するレイヤー・コンポーネントを箇条書き）
- 破壊的変更（インターフェース変更・DB スキーマ変更など）がある場合は強調表示

**書き方のルール**:
- 技術的な詳細はここに書かない（詳細は後続セクションで扱う）
- 変更の「目的」が不明な場合は「コードから読み取れる目的: 〜」と明記する

### Section 2 — ファイル構成マップ

**含めるもの**:
- 変更ファイルのツリー表示（`<pre>` タグ内にASCIIツリー）
- 各ファイルの役割を1行で説明（ファイル名の右に並べる）
- 種別バッジ（実装 / テスト / 設定 / 型 / ドキュメント）

**例**:
```
src/
├── api/
│   ├── users.ts          [実装] ユーザー CRUD エンドポイント
│   └── users.test.ts     [テスト] ユーザーAPIの統合テスト
├── lib/
│   └── cache.ts          [実装] TTL 付き LRU キャッシュ実装
└── types/
    └── user.d.ts         [型] ユーザー関連の型定義
```

### Section 3 — アーキテクチャ概要

**含めるもの**:
1. **レイヤー図** — 変更が関わるアーキテクチャ上の位置を ASCII または表で示す
   ```
   [ブラウザ] → [APIルーター] → [サービス層] → [DBアクセス層] → [DB]
                                      ↕
                                [キャッシュ]
   ```
2. **モジュール依存グラフ** — 変更ファイル同士の依存関係を箇条書き（または `→` 矢印）で示す
3. **主要データフロー** — 代表的なユースケース（例: 「ユーザー作成リクエスト」）がどう流れるかをステップ形式で示す

**ルール**:
- 変更が1ファイルのみで構造が自明な場合はこのセクションを省略してよい
- 図は `<pre>` タグ内のASCIIアートか `<table>` で表現する（外部図ライブラリ不使用）

### Section 4 — コンポーネント詳細

変更ファイルごとに `<details><summary>` で折りたたみ可能なブロックを作る。

**各ブロックに含めるもの**:
- ファイルの役割（2〜3文）
- 主要なエクスポート（関数・クラス・定数）の一覧
- 重要な関数のシグネチャ＋1〜2行の概要

**ルール**:
- 全ての関数を列挙しない。重要度の高いもの（外部から呼ばれるもの・複雑なもの）に絞る
- テストファイルは「何をテストしているか」（テスト対象と境界条件）を箇条書きにする
- 設定ファイルは「何を設定しているか」の要点のみ記載する

### Section 5 — 注目実装ポイント

Step 4 で特定した箇所をここに書く。見つからなかった場合は「特記すべき非自明な実装はありません」と書いてセクション自体は残す。

**各ポイントのフォーマット**:
```
### <ポイントの短いタイトル>
<場所: ファイル名:行番号（概算）>

<コード引用（シンタックスハイライト付き <pre><code> ブロック）>

**何をしているか**: <1〜3文で説明>
**なぜ珍しいか / なぜこの方法を選んだか**: <理由・背景>
**レビュアーが確認すべき点**: <この実装に関して確認すべき観点>（任意）
```

### Section 6 — レビューチェックリスト

変更の内容に応じて、レビュアーが確認すべき観点をチェックリスト形式で示す。以下は基本テンプレート（変更に関係しないものは省略し、変更固有の観点を追加する）：

```
□ セキュリティ
  □ 入力バリデーション（外部入力を無害化しているか）
  □ 認証・認可の欠落がないか
  □ シークレット・個人情報のログ漏洩がないか

□ エラーハンドリング
  □ 例外が適切に捕捉・伝搬されているか
  □ エラー時のフォールバックが定義されているか

□ パフォーマンス
  □ N+1クエリ・不要なループがないか
  □ キャッシュが適切に活用されているか

□ テスト
  □ 新規ロジックのユニットテストがあるか
  □ エッジケース（空・null・境界値）がカバーされているか

□ 後方互換性
  □ APIインターフェースの破壊的変更がないか
  □ DBマイグレーションが必要な場合、ロールバック計画があるか
```

---

## HTML 実装ルール

### スタイル

- CSS は全て `<style>` タグ内にインライン記述（外部ファイル・CDN 不使用）
- カラースキーム: `prefers-color-scheme: dark` で自動ダーク対応
- フォント: `font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif`（web フォント不使用）
- コードフォント: `font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', Consolas, monospace`

### シンタックスハイライト

インライン CSS でキーワードを着色する。`<span class="kw">`, `<span class="str">` などのクラスを付与し、CSS で色を定義する（外部ライブラリ不使用）。

```css
.kw  { color: #7c3aed; }   /* keyword */
.str { color: #059669; }   /* string */
.cm  { color: #6b7280; }   /* comment */
.fn  { color: #2563eb; }   /* function */
.num { color: #d97706; }   /* number */
```

ただし、HTMLエスケープが必要なコード（`<`, `>`, `&` など）は必ずエスケープしてから `<code>` に入れる。

### インタラクション

- アコーディオン: `<details><summary>` タグのみで実装（JS 不要）
- TOCアンカー: `<a href="#sec-N">` でスムーズスクロール（CSS `scroll-behavior: smooth`）
- JS は使用しない（ゼロ JS が原則。ブラウザ標準機能のみ）

### バッジ

```html
<span class="badge badge-impl">実装</span>
<span class="badge badge-test">テスト</span>
<span class="badge badge-config">設定</span>
<span class="badge badge-type">型</span>
<span class="badge badge-doc">ドキュメント</span>
```

### 全体構造テンプレート

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Code Overview — <対象の説明></title>
  <style>
    /* ここにすべてのスタイルをインライン記述 */
  </style>
</head>
<body>
  <header class="sticky-header">
    <h1>Code Overview <span class="scope-label"><対象の説明></span></h1>
    <p class="meta">生成: <日時> | 対象: <スコープ></p>
    <nav>
      <a href="#sec-1">サマリー</a>
      <a href="#sec-2">ファイル構成</a>
      <a href="#sec-3">アーキテクチャ</a>
      <a href="#sec-4">コンポーネント詳細</a>
      <a href="#sec-5">注目実装ポイント</a>
      <a href="#sec-6">レビューチェックリスト</a>
    </nav>
  </header>

  <main>
    <section id="sec-1">...</section>
    <section id="sec-2">...</section>
    <section id="sec-3">...</section>
    <section id="sec-4">...</section>
    <section id="sec-5">...</section>
    <section id="sec-6">...</section>
  </main>

  <footer>
    <p>Generated by /code-overview</p>
  </footer>
</body>
</html>
```

---

## 出力

```
✅ code-overview.html を <プロジェクトルートパス>/code-overview.html に保存しました。
   対象: <スコープの説明>
   変更ファイル数: N
   注目実装ポイント: M 件
```

ブラウザで開くコマンドも表示する（OS に応じて）：
- Linux: `xdg-open code-overview.html`
- macOS: `open code-overview.html`
- WSL: `explorer.exe code-overview.html`

---

## アンチパターン

- **言語仕様の教科書を書かない** — `Array.map()` が「配列を変換する」などは解説しない
- **全ての変更行を逐一説明しない** — コードを読めば分かることを HTML に繰り返さない
- **外部リソースへのリンクを埋め込まない** — CDN・外部画像・web フォントは一切使わない
- **ファイルの中身を丸コピしない** — 全コードを貼り付けるのではなく、重要な部分を引用・要約する
- **「特になし」を書かない** — 注目実装ポイントがない場合は「特記すべき非自明な実装はありません」と書く。空セクションにはしない
- **コミットメッセージを使わない** — コミットメッセージをそのまま転記するのではなく、コードから読み取った内容を書く
- **推測をファクトとして書かない** — コードから確信を持って読み取れない意図は「〜と推測される」と書く
