---
name: code-overview
description: "Claudeが書いたコードのレビュー用HTMLドキュメントを自動生成するスキル。実装の全貌・アーキテクチャ・注目実装ポイントに加え、アーキテクチャ図／フローチャート／シーケンス図／コンポーネントマッピング（React/Vue の画面とコンポーネントの対応）を HTML/CSS だけで描画した自己完結型HTMLをプロジェクトルートに出力する。対象スコープは引数で指定（空=git未コミット差分＋未追跡ファイル、ファイルパス、--commit <sha>、--pr <url or #num>）。/code-overview で起動。"
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

### Section 3 — アーキテクチャ & 図解

このセクションは**図解を主役**にする。レビュアーがコードを読む前に構造を絵で掴めるようにするのが目的。図はすべて **HTML/CSS で描画**する（具体的なテンプレートは後述「図解パターン」）。**Mermaid 等の外部ライブラリ・LLM が座標を手計算する SVG は使わない**。レイアウトはブラウザに計算させる（flex / grid / border）のが鉄則 — 座標を自分で振ると矢印やラベルがサイレントに崩れ、HTML 構造チェックをすり抜ける。

対象の性質に応じて、以下から**該当するものだけ**を描く（無関係な図は描かない）:

| 図 | いつ描くか | 描画方法 |
|---|---|---|
| **アーキテクチャ全体像** | 複数ファイル／レイヤーが関わるとき（ほぼ常時） | 縦積み box（flex column）＋層間に `▼` コネクタ |
| **フローチャート** | 条件分岐・ループ・多段パイプラインなど制御フローが非自明なとき | 縦フロー box。分岐は左右 flex。複雑な合流は避け、単純な形に保つ |
| **シーケンス図** | 複数の層／サービス／モジュールをまたぐ通信（クライアント↔API↔DB、イベント連携など）があるとき | **CSS グリッド**（アクター=列／メッセージ=行）。SVG 座標計算は使わない |
| **コンポーネントマッピング** | 対象に**フロントエンド UI**（React / Vue / Svelte など）が含まれるとき | ワイヤーフレーム（ネスト div）で画面レイアウトを再現し、各領域にコンポーネント名を重ねる |

図だけで伝わらない補足は箇条書きで添える:
- **モジュール依存** — 変更ファイル間の依存を `A → B` で
- **主要データフロー** — 代表ユースケースが通る経路を 1 本、ステップで

**ルール**:
- 変更が 1 ファイルのみで構造が自明なら、全体像だけ（または本セクション省略）でよい
- 図は**正確さ優先**。推測で関係を描かず、コードから読み取れた構造だけ描く（不明な箇所は描かないか「未確認」と注記）
- 1 図に詰め込みすぎない。要素が多いときは「主要経路」に絞る（網羅より理解しやすさ）

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

### カラートークン（必ず `:root` に定義する）

本ドキュメントの全 CSS（シンタックスハイライト・バッジ・図解パターン）は以下の CSS 変数を参照する。**`<style>` の先頭で必ず定義すること**（未定義だと色がフォールバックして図がサイレントに崩れる）。

```css
:root {
  --bg:#ffffff; --fg:#1f2328; --muted:#57606a; --border:#d0d7de; --card:#f6f8fa;
  --accent:#0969da; --accent-bg:#ddf4ff; --warn-bg:#fff8c5; --warn-border:#d4a72c;
  --kw:#7c3aed; --str:#059669; --cm:#6b7280; --fn:#2563eb; --num:#d97706;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg:#0d1117; --fg:#e6edf3; --muted:#8b949e; --border:#30363d; --card:#161b22;
    --accent:#58a6ff; --accent-bg:#121d2f; --warn-bg:#2d2611; --warn-border:#bb8009;
    --kw:#d2a8ff; --str:#7ee787; --cm:#8b949e; --fn:#79c0ff; --num:#ffa657;
  }
}
body { background: var(--bg); color: var(--fg); }
```

### シンタックスハイライト

インライン CSS でキーワードを着色する。`<span class="kw">`, `<span class="str">` などのクラスを付与し、上記カラートークンを参照する（外部ライブラリ不使用。ダークモードでも自動で色が切り替わる）。

```css
.kw  { color: var(--kw); }   /* keyword */
.str { color: var(--str); }  /* string */
.cm  { color: var(--cm); }   /* comment */
.fn  { color: var(--fn); }   /* function */
.num { color: var(--num); }  /* number */
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

### 図解パターン（すべて HTML/CSS。座標計算なし）

**鉄則: レイアウトはブラウザに計算させる。** flex / grid / border で組み、要素の幅は内容に合わせて自動で決める（固定 px を避け、最低幅が要るときだけ `minmax()` / `min-width` を使う）。LLM が x/y を手で振る SVG は、矢印やラベルが重なってもチェックをすり抜けて壊れるので使わない。色は既存の CSS 変数（`--accent` / `--border` / `--card` など）を流用する。HTML に直接書く `<`・`>`（コンポーネント名など）は CSS の `content` 側で組み立てて属性値に山括弧を入れないようにすると安全。

#### 共通スタイル（一度だけ定義）

```css
.dgm { margin: 16px 0; }
.dgm-cap { font-size: 0.8rem; color: var(--muted); margin: 0 0 6px; }
/* 縦積みノード（アーキテクチャ／フローチャート共通） */
.stack { display: flex; flex-direction: column; align-items: center; gap: 0; }
.node { border: 1px solid var(--border); background: var(--card); border-radius: 8px;
  padding: 8px 14px; text-align: center; max-width: 90%; }
.node.start, .node.end { border-radius: 999px; }            /* 開始/終了は丸み強め */
.node.decision { background: var(--warn-bg); border-color: var(--warn-border); } /* 分岐 */
.node.io { border-style: dashed; }                          /* 入出力 */
.conn { color: var(--muted); line-height: 1.1; padding: 2px 0; }   /* ▼ コネクタ */
.branch { display: flex; gap: 24px; justify-content: center; align-items: flex-start;
  flex-wrap: wrap; }
.branch > .path { display: flex; flex-direction: column; align-items: center; gap: 0; }
.branch .label { font-size: 0.72rem; color: var(--accent); font-weight: 600; }
```

#### 1. アーキテクチャ全体像 / フローチャート（縦積み）

ノードを縦に積み、間に `▼`。分岐は `.branch` で左右に分ける（合流が複雑なら無理に線で繋がず、ノード名で参照する）。

```html
<div class="dgm">
  <p class="dgm-cap">図: リクエスト処理フロー</p>
  <div class="stack">
    <div class="node start">リクエスト受信</div>
    <div class="conn">▼</div>
    <div class="node">入力バリデーション</div>
    <div class="conn">▼</div>
    <div class="node decision">認証トークン有効?</div>
    <div class="branch">
      <div class="path"><span class="label">Yes ▼</span><div class="node">ハンドラ実行</div></div>
      <div class="path"><span class="label">No ▼</span><div class="node end">401 を返す</div></div>
    </div>
  </div>
</div>
```

横方向の層構造（例: `[UI] → [API] → [DB]`）を見せたいときは `.branch` を 1 行の flex として使い、間に `→` を挟む。

#### 2. シーケンス図（CSS グリッド）

**アクター = 列、メッセージ = 行**。位置はすべてグリッドが計算する（座標計算なし）。列数は `--n` に、各メッセージは「何列目から何列目へ」を `grid-column` の整数で指定するだけ。

```css
.seq { display: grid; grid-template-columns: repeat(var(--n), minmax(90px, 1fr));
  grid-auto-rows: minmax(30px, auto); align-items: center; row-gap: 6px; position: relative; }
.seq .actor { grid-row: 1; align-self: start; text-align: center; font-weight: 600;
  font-size: 0.82rem; border: 1px solid var(--border); background: var(--card);
  border-radius: 6px; padding: 6px 4px; }
.seq .life { grid-row: 2 / -1; width: 0; border-left: 1px dashed var(--muted);
  justify-self: center; }                       /* 各アクターのライフライン */
.seq .msg { align-self: end; text-align: center; font-size: 0.78rem; color: var(--fg);
  border-bottom: 1.5px solid var(--accent); padding: 0 6px 4px; position: relative;
  z-index: 1; }
.seq .msg::after { content: ''; position: absolute; bottom: -5px; right: -1px;
  border: 5px solid transparent; border-left-color: var(--accent); }   /* → 矢じり */
.seq .msg.rtl::after { right: auto; left: -1px;
  border-left-color: transparent; border-right-color: var(--accent); } /* ← 矢じり */
.seq .msg.async { border-bottom-style: dashed; }                       /* 応答/非同期 */
```

```html
<div class="dgm">
  <p class="dgm-cap">図: ログインのシーケンス</p>
  <div class="seq" style="--n: 3">
    <div class="actor" style="grid-column: 1">Client</div>
    <div class="actor" style="grid-column: 2">API</div>
    <div class="actor" style="grid-column: 3">DB</div>
    <div class="life" style="grid-column: 1"></div>
    <div class="life" style="grid-column: 2"></div>
    <div class="life" style="grid-column: 3"></div>
    <!-- 各メッセージ: grid-row は 2 から連番、grid-column は「左端列 / 右端列+1」 -->
    <div class="msg"      style="grid-row: 2; grid-column: 1 / 3">POST /login</div>
    <div class="msg"      style="grid-row: 3; grid-column: 2 / 4">SELECT user</div>
    <div class="msg async rtl" style="grid-row: 4; grid-column: 2 / 4">row</div>
    <div class="msg async rtl" style="grid-row: 5; grid-column: 1 / 3">200 + token</div>
  </div>
</div>
```

- `grid-column: a / b+1` で a 列目〜b 列目をまたぐ（CSS の終端は排他的なので右端列＋1）。
- 左→右は既定、右→左は `rtl` を付ける（`grid-column` は常に小さい列 / 大きい列で書く）。
- 応答・非同期は `async`（破線）。自己呼び出し（同一列）は 1 列に短いメッセージを置く。

#### 3. コンポーネントマッピング（ワイヤーフレーム重ね）

ネストした div で**実際の画面レイアウトを再現**し、各領域の左上にコンポーネント名バッジを重ねる。バッジは `data-cmp` 属性を CSS の `content` で `<Name />` に整形する（属性値に山括弧を入れない）。

```css
.wf { border: 1px solid var(--border); border-radius: 8px; padding: 8px; }
.wf-box { position: relative; border: 1.5px dashed var(--accent); border-radius: 6px;
  padding: 20px 10px 12px; margin: 8px 6px; }
.wf-box::before { content: "<" attr(data-cmp) " />"; position: absolute; top: 0; left: 0;
  font-family: monospace; font-size: 0.68rem; color: #fff; background: var(--accent);
  padding: 1px 6px; border-radius: 6px 0 6px 0; }
.wf-row { display: flex; gap: 8px; }
.wf-row > .wf-aside { flex: 0 0 30%; }
.wf-row > .wf-main  { flex: 1; }
.wf-note { font-size: 0.72rem; color: var(--muted); }    /* 領域の中身メモ */
```

```html
<div class="dgm">
  <p class="dgm-cap">図: 一覧画面のコンポーネント対応</p>
  <div class="wf">
    <div class="wf-box" data-cmp="Header"><span class="wf-note">ロゴ / 検索 / ユーザーメニュー</span></div>
    <div class="wf-row">
      <div class="wf-box wf-aside" data-cmp="FilterSidebar"><span class="wf-note">カテゴリ絞り込み</span></div>
      <div class="wf-box wf-main" data-cmp="ProductList">
        <div class="wf-box" data-cmp="ProductCard"><span class="wf-note">画像 / 価格 / カート</span></div>
        <div class="wf-box" data-cmp="ProductCard"><span class="wf-note">画像 / 価格 / カート</span></div>
      </div>
    </div>
    <div class="wf-box" data-cmp="Footer"><span class="wf-note">リンク / 著作権</span></div>
  </div>
</div>
```

- ネストの入れ子＝コンポーネントの親子関係。画面上の位置と DOM ツリーが一致するので「どこが何コンポーネントか」が一目で分かる。
- props や state を補足したいときは `.wf-note` に 1 行で添える（詳細は Section 4 のコンポーネント詳細へ）。

### 全体構造テンプレート

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Code Overview — <対象の説明></title>
  <style>
    /* 先頭に「カラートークン」の :root 定義を必ず置く。
       続けてレイアウト・シンタックスハイライト・バッジ・図解パターンの CSS をインライン記述 */
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
- **図の座標を手計算しない** — SVG に x/y を直接振ると矢印・ラベルが重なってもチェックを通過して壊れる。レイアウトはブラウザ（flex / grid / border）に計算させる
- **固定 px でレイアウトを組まない** — ラベルが長い・ノードが多いと固定値は破綻する。内容に合わせた auto-sizing（必要時のみ `minmax()` / `min-width`）にする
- **無関係な図を描かない** — 対象に該当しない図種（例: バックエンドのみなのにコンポーネントマッピング）は出さない。図は理解を助けるときだけ描く
- **1 図に詰め込みすぎない** — 全要素を 1 枚に押し込まず、主要経路に絞る（網羅より可読性）
