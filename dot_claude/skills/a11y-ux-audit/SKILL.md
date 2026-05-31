---
name: a11y-ux-audit
description: "Web ページとそのサイト内リンクを辿り、ページごとにアクセシビリティ／ユーザビリティ／パフォーマンスの評価レポートを生成するスキル。定量=Lighthouse（a11y/performance などの 0-100 スコア＋影響 DOM ノード）と Core Web Vitals 実測、定性=Nielsen の 10 ユーザビリティヒューリスティック walk-through（所見ごとに severity 0-4）を併用する。各所見に URL・評価項目・点数・改善要否・該当要素（CSS セレクタ or UI 位置）・推奨対応を記載。`/a11y-ux-audit <起点URL> [オプション]` で起動。サイト診断・アクセシビリティ監査・WCAG・ヒューリスティック評価・UX レビューの依頼で使う。実ユーザーテスト（モデレート・SUS）の代替ではない。"
---

あなたは Web サイトのアクセシビリティ・ユーザビリティ・パフォーマンスを評価する監査者です。起点 URL から同一オリジンのリンクを辿り、**ページごとに評価レポート**を生成します。

## 評価の二軸（最重要の設計原則）

点数の出所を**定量＝ツール由来**と**定性＝ヒューリスティック**に厳密に分ける。これがユーザーの「定量・定性」要件にそのまま対応する。

| 軸 | 出所 | 点数 |
|---|---|---|
| **定量（再現可能）** | Lighthouse のカテゴリスコア（accessibility / performance、必要なら best-practices / seo）＋ Core Web Vitals 実測 | 各 **0-100**（Lighthouse 出力値をそのまま転記）／ CWV は実測値＋良好/要改善/不良 |
| **定性（専門家判断）** | Nielsen の 10 ユーザビリティヒューリスティックの walk-through | 所見ごとに **severity 0-4**（0=問題なし, 1=cosmetic, 2=minor, 3=major, 4=catastrophe） |

**禁止**: ヒューリスティック評価を LLM 判断で 0-100 のグローバルスコアに丸めること（実行ごとにブレて再現性がなく、定量を装った主観になる＝false precision）。usability の「点数」は severity 0-4 で表す。

## 正直な枠付け（レポートヘッダに必ず埋め込む）

注意書きとして本文の片隅に置くのではなく、**出力レポートの冒頭ヘッダに毎回挿入**する：

- 自動検出（Lighthouse / axe）は WCAG 達成基準の **約 25-40% しかカバーしない**。スコアは「下限」であり「アクセシブルの証明」ではない。
- 本スキルは**自動＋専門家（ヒューリスティック）評価**であり、**実ユーザーテスト（モデレートセッション・SUS・タスク成功率）の代替ではない**。

## 入力（引数）

`/a11y-ux-audit <起点URL> [オプション]`

| オプション | 既定 | 意味 |
|---|---|---|
| `<起点URL>` | 必須 | クロールの起点 |
| `--max-pages N` | 10 | 評価する最大ページ数（対象サイトへの負荷防御も兼ねる） |
| `--depth N` | 2 | クロールの最大深さ（起点を 0 とする） |
| `--scope` | `same-origin` | `same-origin`（既定） / `same-host`（サブドメイン許容） / `list:<url,url,...>`（クロールせず列挙 URL のみ評価） |
| `--format` | `B` | `B`（単一統合 MD・既定） / `A`（ページ別 MD ＋ index） / `C`（CSV+JSON+サマリ） / `all` |
| `--focus` | `all` | `all`（a11y＋UX＋perf 包括・既定） / `a11y` / `ux` |
| `--out <dir>` | `./reports/a11y-ux-audit/<YYYY-MM-DD>-<host>/` | 出力先ディレクトリ |

引数が省略された・曖昧なときは起点 URL とスコープをユーザーに確認してから進む。

## フロー

### 0. 前提確認

- `node` / `npx` と Chrome（`/Applications/Google Chrome.app` 等）の存在を確認する。
- Lighthouse は global インストール不要。`npx -y lighthouse` で都度実行する。
- Playwright MCP（`browser_navigate` / `browser_snapshot` / `browser_take_screenshot` / `browser_evaluate`）が使えることを確認。初回は専用ブラウザの導入が必要で、`Browser "chrome-for-testing" is not installed` エラーが出たら `npx @playwright/mcp install-browser chrome-for-testing` を一度実行する。
- いずれかが欠けるときは「失敗時フォールバック」に従う。

### 1. クロール（同一オリジン）

`--scope list:` 指定時はクロールせず列挙 URL を評価対象キューに入れる。それ以外は起点からリンクを辿る：

- **リンク発見**: 各ページを `browser_navigate` で開き、`browser_evaluate` で `a[href]` を抽出する（`[...document.querySelectorAll('a[href]')].map(a => a.href)`）。
- **URL 正規化して dedupe**: 末尾スラッシュを揃え、`#fragment` を除去し、トラッキングクエリ（`utm_*` / `gclid` / `fbclid` 等）を除去してから重複排除する。
- **スキップ対象**: `#anchor` のみのリンク / `mailto:` / `tel:` / `javascript:` / 非 HTML（`.pdf` `.zip` `.jpg` `.png` `.mp4` 等の拡張子）/ スコープ外オリジン。
- **ループガード**: ページネーション（`?page=2,3,...`）やクエリ爆発を検知したら打ち切る。`--max-pages` と `--depth` を**厳守**する。
- 訪問済み・キューを明示的に管理し、BFS で `--depth` まで辿る。

### 2. ページごと評価

各 URL に対して定量と定性を取得する。

**定量（ツール）— Lighthouse:**

```sh
npx -y lighthouse "<url>" \
  --output=json --output-path="<out>/lh/<page-slug>.json" \
  --quiet --only-categories=accessibility,performance \
  --chrome-flags="--headless=new"
```

- `--only-categories` は `--focus` に応じて決める:

  | `--focus` | `--only-categories` |
  |---|---|
  | `all`（既定） | `accessibility,performance` |
  | `a11y` | `accessibility` |
  | `ux` | `accessibility,performance`（定性ヒューリスティックが主軸だが定量も取る） |

  `best-practices` / `seo` は副次扱い。必要なときだけ `--only-categories` に明示追加する。
- **⚠ JSON を context に丸ごと載せない**: Lighthouse の JSON は 1 ページ数 MB。`--output-path` でファイルに保存し、`jq` で**必要部分だけ抽出**する。`cat` / Read でフル JSON を読み込まない（`--max-pages` 既定 10 で完走できるかの分かれ目）。

  ```sh
  # カテゴリスコア（0-1 → 100 倍）
  jq '.categories | to_entries | map({(.key): (.value.score*100|round)}) | add' "<json>"

  # 失敗 audit と影響 DOM ノード（CSS セレクタ / snippet）
  jq '[.audits | to_entries[]
        | select(.value.scoreDisplayMode=="binary" and .value.score==0)
        | {id:.key, title:.value.title,
           nodes: [(.value.details.items // [])[] | {selector:.node.selector, snippet:.node.snippet}]}]' "<json>"
  ```

**Core Web Vitals:**

- `jq` で `.audits["largest-contentful-paint"].numericValue`（LCP）、`.audits["cumulative-layout-shift"].numericValue`（CLS）、`.audits["total-blocking-time"].numericValue`（TBT）を取得。
- 閾値（web.dev 基準）: **LCP < 2.5s 良好 / 2.5-4s 要改善 / >4s 不良**、**CLS < 0.1 良好 / 0.1-0.25 要改善 / >0.25 不良**。
- **INP は lab の Lighthouse では測定できない**。代理として TBT を使い、レポートには `TBT (lab proxy)` と明記する（`INP` と称さない）。閾値: **TBT < 200ms 良好 / 200-600ms 要改善 / >600ms 不良**。

**定性（ヒューリスティック）— Nielsen 10:**

- `browser_snapshot`（aria tree）と `browser_take_screenshot` を取得し、画面を walk-through する。
- Nielsen の 10 ヒューリスティックを観点に所見を挙げる:
  1. システム状態の可視性
  2. 実世界との一致
  3. ユーザーの自由と制御
  4. 一貫性と標準
  5. エラー予防
  6. 記憶より認識
  7. 柔軟性と効率性
  8. 美的で最小限のデザイン
  9. エラーからの回復支援
  10. ヘルプとドキュメント
- 各所見に **severity 0-4** と **該当 UI 位置（記述的）** を付ける。問題が無いヒューリスティックは無理に挙げない。

### 3. スコア＋改善要否の判定

防御可能な定義に従う（曖昧な印象で決めない）：

- 定量スコアは **Lighthouse の出力値をそのまま転記**（LLM で再計算・推測しない。実行していない値を「だいたい 80」と書かない）。
- **改善要否**:
  - a11y スコア < 90、または `serious` / `critical` 相当の違反あり → 改善要
  - CWV が「要改善」「不良」帯 → 改善要
  - ヒューリスティック severity ≥ 3（major / catastrophe）→ 改善要
- **「どの要素か」の粒度**: axe / Lighthouse 由来 = **CSS セレクタ**（精密）／ ヒューリスティック由来 = **記述的な UI 位置**（例：「ヘッダーの送信ボタン周辺」）。
- ページ単位の「UX 重大度」列 = そのページのヒューリスティック最大 severity。

### 4. レポート生成

`--format` に従って出力する。**全形式共通の必須フィールド**:

> URL ／ 評価項目 ／ スコア（or severity）／ 改善要否 ／ 該当要素 ／ 推奨対応

- **ヘッダに「正直な枠付け」を必ず挿入**する（前述）。
- **凡例で点数の対応を明示**する: 「a11y / perf = Lighthouse の 0-100 スコア、**usability = Nielsen severity 0-4 が点数に相当**（0=問題なし〜4=catastrophe）」。usability だけ点数が無いように見えるのを防ぐ。
- **逐次書き出し（all-then-write にしない）**: 1 ページ評価するごとに per-page 中間ファイルへ保存（または出力ファイルへ追記）し、最後に統合する。ループ途中で落ちても全損しないように（形式 A は自然にこうなる。B / C も同様に）。

### 5. 保存＋サマリ提示

`--out` に書き出し、サイト全体サマリ表と優先度付き改善バックログをユーザーに提示する。レポート末尾に「準拠基準」として出典を明記する（後述）。

## 出力フォーマット（既定 B）

### B（既定）単一統合 Markdown

```markdown
# サイト評価レポート: <host>

評価日: YYYY-MM-DD ／ 対象: <起点URL> ／ 評価ページ数: N

> 注記: 自動＋専門家（ヒューリスティック）評価です。自動検出は WCAG 達成基準の約 25-40% のみカバーし、
> スコアは下限です。実ユーザーテスト（モデレート/SUS）の代替ではありません。
> 凡例: a11y・perf = Lighthouse 0-100 スコア／ usability = Nielsen severity 0-4。

## サマリ

| URL | a11y | perf | UX重大度 | 改善要 |
|-----|------|------|---------|-------|
| /        | 82 | 70 | major (3) | ◯ |
| /pricing | 91 | 88 | minor (2) | —（基準内） |

## 改善バックログ（優先度順）

1. [serious] コントラスト不足 `.btn-primary` (/) → コントラスト比 4.5:1 以上へ
2. [major]   処理中の状態表示なし（送信ボタン周辺, /）→ ローディングインジケータ追加

## ページ別詳細

### https://example.com/
- **定量**: a11y 82 / perf 70 ／ LCP 3.1s（要改善）/ CLS 0.05（良好）/ TBT (lab proxy) 320ms
- **アクセシビリティ所見**:
  - [serious] ボタンに名前なし → `button.nav-toggle` ／ aria-label を付与
- **ユーザビリティ所見（Nielsen）**:
  - [#1 状態の可視性 / severity 3] 送信時に処理中表示がない（送信ボタン周辺）→ ローディング表示
```

### A ページ別 Markdown ＋ index.md

`index.md`（サイト全体サマリ表）＋ 1 ページ 1 ファイル（`<page-slug>.md` に詳細所見）。所見が多く深掘りしたい場合向き。

### C 構造化データ ＋ サマリ

`findings.csv` / `findings.json`（1 行 = 1 所見）＋ `summary.md`（集計・前回実行との差分＝経時比較用）。列：

```
url,category,item,score_or_severity,needs_fix,element,recommendation
```

`category` は `a11y` / `usability` / `performance`。スプレッドシート・BI 取り込みや定点観測向き。

## CSP / 失敗時フォールバック

- **生 `browser_evaluate` で CDN から axe を `<script>` 注入しない**。実サイトの CSP `script-src` でブロックされ沈黙失敗する。a11y 検出は Lighthouse 経由に一本化する（Lighthouse は内部で axe を Chrome に正規注入するため CSP を回避する）。
- Lighthouse が落ちる（認証・ボット対策・タイムアウト）→ そのページは「**定量取得不可**」と理由付きで明記し、MCP snapshot ベースのヒューリスティック評価のみ実施する。
- 認証必須サイト → ユーザーに方法を確認（Lighthouse への Cookie / ヘッダ受け渡し、または対象から除外）。
- Chrome の自動検出が外れる → `CHROME_PATH` 環境変数で実行パスを渡す（例: `CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"`）。
- node / npx / Chrome のいずれも無い → 評価不能を報告し、何が必要かを伝える。
- Playwright MCP が使えない（ブラウザ未導入で install もできない等）→ `chrome-devtools` MCP（`navigate` / `evaluate` / `screenshot`）または `playwright-cli` スキルで snapshot・screenshot・リンク抽出を代替する。
- リンク抽出が JS レンダリング依存で取れない → `browser_snapshot` の aria tree からリンクを拾う。

## アンチパターン

- ヒューリスティック評価を 0-100 のグローバルスコアに丸める（false precision）
- Lighthouse を実行せずスコアを「だいたい 80」と推測で書く
- Lighthouse の JSON 全体を `cat` / Read で context に載せ、数ページで枯渇させる
- 自動検出だけで「アクセシブル」と結論づける
- クロール上限なしでサイト全体を舐める／別オリジンまで辿る
- CDN script 注入を前提に設計する（CSP で沈黙失敗）
- 全ページ評価し終えてから一括書き出し（途中で落ちると全損）

## 準拠基準（レポート末尾に出典として明記）

- **WCAG 2.2 Level AA**（W3C, 2023 勧告。axe-core が A/AA/AAA を網羅）— https://www.w3.org/TR/WCAG22/
- **Nielsen の 10 Usability Heuristics ＋ severity 0-4 スケール**（NN/g, 1994）— https://www.nngroup.com/articles/ten-usability-heuristics/
- **Core Web Vitals**（web.dev: LCP / INP / CLS）— https://web.dev/articles/vitals
- **Lighthouse**（Google。a11y 監査は内部で axe-core を使用）— https://developer.chrome.com/docs/lighthouse

## 失敗時の振る舞い（まとめ）

- 素材・URL が取得できない → ユーザーに到達可能な URL を確認して続行
- 一部ページのみ失敗 → そのページを「定量取得不可」と明記し、残りは継続（途中で全体を止めない）
- ユーザーが途中で打ち切り → そこまでに評価したページでレポートを生成し、未評価ページを明示
