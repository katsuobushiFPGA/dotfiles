---
name: a11y-ux-audit
description: "Web ページとそのサイト内リンクを辿り、ページごとにアクセシビリティ／ユーザビリティ／パフォーマンスの評価レポートを生成するスキル。定量=Lighthouse（a11y/performance などの 0-100 スコア＋影響 DOM ノード）と Core Web Vitals 実測、定性=Nielsen の 10 ユーザビリティヒューリスティック walk-through（所見ごとに severity 0-4）を併用する。各所見に URL・評価項目・点数・改善要否・該当要素（CSS セレクタ or UI 位置）・推奨対応を記載。`/a11y-ux-audit <起点URL> [オプション]` で起動。サイト診断・アクセシビリティ監査・WCAG・ヒューリスティック評価・UX レビューの依頼で使う。実ユーザーテスト（モデレート・SUS）の代替ではない。"
---

あなたは Web サイトのアクセシビリティ・ユーザビリティ・パフォーマンスを評価する監査者です。起点 URL から同一オリジンのリンクを辿り、**ページごとに評価レポート**を生成します。

## 重要ルール早見表（索引。詳細は各セクションへ）

| ルール | 値 |
|---|---|
| 既定値 | `--max-pages 10` / `--depth 2`（起点=0）/ `--scope same-origin` / `--format B` / `--focus all` |
| 定量の点数 | Lighthouse カテゴリスコア **0-100 をそのまま転記**（推測・再計算しない） |
| 定性の点数 | Nielsen **severity 0-4**（0-100 に丸めない＝false precision 禁止） |
| Lighthouse カテゴリ（`--focus`） | `all`→`accessibility,performance` / `a11y`→`accessibility` / `ux`→`accessibility,performance` |
| CWV 閾値（良好の上限） | LCP < 2.5s / CLS < 0.1 / TBT(lab proxy) < 200ms |
| 改善要否（いずれか該当で「要」） | a11y < 90 or weight ≥ 7 の失敗 audit / CWV 要改善・不良帯 / ヒューリスティック severity ≥ 3 |
| a11y 所見の severity・優先度 | Lighthouse auditRefs の **weight** 由来（10=critical / 7=serious / 3=moderate / 1=minor）。捏造しない |
| 該当要素の粒度 | Lighthouse 由来 = **CSS セレクタ** / ヒューリスティック由来 = **記述的 UI 位置** |
| 必須フィールド（全形式共通） | URL / 評価項目 / スコア(or severity) / 改善要否 / 該当要素 / 推奨対応 |
| JSON 取り扱い | ファイル保存 → `jq` 抽出。全文を `cat` / Read しない |
| レポートヘッダ | 「正直な枠付け」（自動検出は WCAG の約 25-40%／実ユーザーテストの代替でない）を毎回挿入 |
| ブラウザ未導入時 | install 可なら 1 度だけ導入。install 不可・禁止なら導入せず chrome-devtools MCP へフォールバック |
| 定性 degraded 判定 | walk-through を完遂できれば full（aria snapshot 無くても screenshot＋DOM で可）。walk-through 自体が不能な時だけ degraded 明記 |

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
- Playwright MCP（`browser_navigate` / `browser_snapshot` / `browser_take_screenshot` / `browser_evaluate`）が使えることを確認。初回は専用ブラウザの導入が必要で、`Browser "chrome-for-testing" is not installed` エラーが出たら `npx @playwright/mcp install-browser chrome-for-testing` を一度実行する。**ただし install が不可・禁止の環境（CI・サンドボックス・リソース制約で「install するな」と指示された場合など）では install せず**、「CSP / 失敗時フォールバック」節の chrome-devtools MCP 経路に切り替える（install を既定の必須手順と読まない）。
- いずれかが欠けるときは「失敗時フォールバック」に従う。

### 1. クロール（同一オリジン）

`--scope list:` 指定時はクロールせず列挙 URL を評価対象キューに入れる。それ以外は起点からリンクを辿る：

- **リンク発見**: 各ページを `browser_navigate` で開き、`browser_evaluate` で `a[href]` を抽出する（`[...document.querySelectorAll('a[href]')].map(a => a.href)`）。
- **URL 正規化して dedupe**: 末尾スラッシュを揃え、`#fragment` を除去し、トラッキングクエリ（`utm_*` / `gclid` / `fbclid` 等）を除去してから重複排除する。
- **スキップ対象**: `#anchor` のみのリンク / `mailto:` / `tel:` / `javascript:` / 非 HTML（`.pdf` `.zip` `.jpg` `.png` `.mp4` 等の拡張子）/ スコープ外オリジン。
- **ループガード**: ページネーション（`?page=2,3,...`）やクエリ爆発を検知したら打ち切る。`--max-pages` と `--depth` を**厳守**する。
- 訪問済み・キューを明示的に管理し、BFS で `--depth` まで辿る。
- **frontier の決定的順序（`--max-pages` で切り詰める時）**: `same-origin` は scheme+host 粒度の判定でサブツリーの概念を持たない。上限で frontier を切る際は、同一深さ内で次の順に詰める:
  - **group(1)（優先）= 起点ディレクトリを接頭辞に持つ URL**。起点ディレクトリ＝起点 URL の最後の `/` まで（例: `…/demos/bad/before/home.html` → `…/demos/bad/before/`）。判定は文字列 `startsWith` 一致で、**配下のサブディレクトリも含む**（例: `…/before/reports/home.html` は group(1)。`…/before/news.html` も group(1)）。group(1) 内は document 出現順。
  - **group(2)（後回し）= 同一オリジンだが起点ディレクトリ配下でない URL**。document 出現順。
  - **group 内に sub-rank は設けない（目的は決定性であって代表性ではない）**: group(1) 内で「同階層の content（例: `…/before/news.html`）」と「より深い meta サブディレクトリ（例: `…/before/reports/home.html`）」のどちらを先に詰めるかは、**document 出現順がそのまま最終順**。深さや「どれが本体らしいか」での並べ替えはしない（`reports/` `annotated/` を auxiliary と決め打つのはサイト依存で、`…/products/widget/` のようにサブディレクトリ側が本体のサイトでは裏目に出る）。特定ページを優先して評価したいときは `--scope list:<url,...>` で明示する。
  - これにより起点が大規模サイトの一部（例: `…/demos/bad/before/` のようなサブツリー）でも、`--max-pages` 2〜3 のときに監査対象がサイト本体トップへ逸れず起点サブツリーに留まる。順序が述語で決まらないと実行ごとに 2 ページ目が変わり再現性を欠く。

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

  # 失敗 audit を weight 付きで抽出し weight 降順で並べる（CSS セレクタ / snippet も取得）
  jq '(.categories.accessibility.auditRefs | map({(.id): .weight}) | add) as $w
      | [.audits | to_entries[]
          | select(.value.scoreDisplayMode=="binary" and .value.score==0)
          | select($w[.key] != null)   # accessibility 監査のみ（perf 等の binary 失敗が weight 0 で混入するのを防ぐ）
          | {id:.key, title:.value.title, weight: $w[.key],
             nodes: [(.value.details.items // [])[] | {selector:.node.selector, snippet:.node.snippet}]}]
      | sort_by(-.weight)' "<json>"
  ```

  `.audits` はカテゴリ横断のフラット辞書なので、`select($w[.key] != null)` で a11y の `auditRefs` に載る監査だけに絞る（`// 0` で weight 0 を生やすと非 a11y 監査が a11y 所見として漏れ込む）。

- **severity ラベルと優先度は weight から導出する（捏造しない）**。Lighthouse の accessibility `weight` は axe impact 由来で、**10=critical / 7=serious / 3=moderate / 1=minor / 0=参考（閾値未満）** にマップする。a11y の `auditRefs` には weight 0 の監査（`td-has-header` 等の補助的チェック）も含まれるので、**weight 0 は `参考` 表記とし改善要否は「否」**（改善要否トリガは weight ≥ 7 なので weight 0 は要にならない）。改善バックログの `[critical]`/`[serious]` ラベルと優先度順はこの weight で決める（同 weight は影響ノード数の多い順）。weight は `--only-categories` に `accessibility` を含めたときだけ取れる。Lighthouse は impact 文字列を直接は持たないため、weight 以外を severity の根拠にしない。

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
  - a11y スコア < 90、または weight ≥ 7（serious / critical 相当）の失敗 audit あり → 改善要
  - CWV が「要改善」「不良」帯 → 改善要
  - ヒューリスティック severity ≥ 3（major / catastrophe）→ 改善要
- **performance の改善要否は CWV／ラボメトリック帯（LCP / CLS / TBT）を source of truth とし、perf カテゴリ 0-100 そのものはトリガにしない**（設計判断）。合成スコアはサマリ表に転記して傾向把握に使うが、改善要否の判定には用いない — (1) throttling 条件でランごとに振れる、(2) Lighthouse のスコアカーブは web.dev のユーザー基準帯より厳しく（例: LCP 2.4s は「良好」帯でも合成スコアでは中位に沈む）、合成スコアで gating すると over-flag するため。a11y にだけ `< 90` のカテゴリ閾値があるのは、a11y 監査が timing 非依存で決定的に pass/fail するから（timing に揺れる perf とは性質が異なる）。この非対称は意図的であり「perf にも < 90 を入れ忘れた」ではない。
- **「どの要素か」の粒度**: axe / Lighthouse 由来 = **CSS セレクタ**（精密）／ ヒューリスティック由来 = **記述的な UI 位置**（例：「ヘッダーの送信ボタン周辺」）。
- ページ単位の「UX 重大度」列 = そのページのヒューリスティック最大 severity。

### 4. レポート生成

`--format` に従って出力する。**全形式共通の必須フィールド**:

> URL ／ 評価項目 ／ スコア（or severity）／ 改善要否 ／ 該当要素 ／ 推奨対応

- **粒度（per-finding か per-page か）**: 必須フィールドは **所見（finding）単位**に持たせる。**1 所見 = 失敗 audit 1 件（a11y）／ CWV メトリック 1 件（performance）／ ヒューリスティック所見 1 件（usability）**。ページ単位のスコア（Lighthouse カテゴリ 0-100）は所見ではないので**サマリ表に置く指標**とし、所見行にはしない。
- **改善要否も finding 単位で判定**する: a11y は weight ≥ 7 で「要」／ performance は CWV が要改善・不良帯で「要」／ usability は severity ≥ 3 で「要」。**ページ単位の「改善要」列**＝配下 finding のいずれかが「要」、または a11y スコア < 90 のとき「要」（page と finding の判定入力を混同しない）。
- **改善要否フィールドの「示し方」だけが形式依存（不変条件は全形式共通）**: 必須フィールドの「改善要否」は **各 finding について判定可能な形で必ず示す** のが全形式共通の不変条件。差は描画方法のみ:
  - 形式 **A / C**: 所見行に `改善要否` / `needs_fix` 列を**明示**で持たせる。
  - 形式 **B**: 所見行に severity / CWV 帯を載せ（**改善要否はそこから一意に導出可能** ＝ weight≥7 / CWV要改善・不良 / severity≥3）、加えてサマリ表の「改善要」列（page rollup）＋改善バックログ（「要」の finding を列挙）で示す。**B では導出可能な形で示せば必須フィールドを満たしたとみなす**（明示列は不要。「必須＝finding 単位」と「B は明示列なし」は矛盾しない）。
- **ヘッダに「正直な枠付け」を必ず挿入**する（前述）。
- **凡例で点数の対応を明示**する: 「a11y / perf = Lighthouse の 0-100 スコア、**usability = Nielsen severity 0-4 が点数に相当**（0=問題なし〜4=catastrophe）」。usability だけ点数が無いように見えるのを防ぐ。
- **逐次書き出し（all-then-write にしない）**: 1 ページ評価するごとに per-page 中間ファイルへ保存（または出力ファイルへ追記）し、最後に統合する。ループ途中で落ちても全損しないように（形式 A は自然にこうなる。B / C も同様に）。**保護対象は再実行コストの高い成果（Lighthouse の JSON と per-page の jq 抽出結果）**。これらを per-page で durable 化していれば、最終の統合・集計（CSV / サマリの組み立て）は決定的に再生成できるため all-then-write でもよい。

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

**必須フィールドのスコープ（per-file 形式の扱い）**: 形式 A は 1 ファイル = 1 URL なので、**ファイルスコープで一意に決まるフィールド（URL）はファイル冒頭ヘッダに 1 回書けば必須要件を満たす**（所見行ごとに URL を反復しなくてよい）。所見ごとに変わるフィールド（評価項目 / スコア or severity / 改善要否 / 該当要素 / 推奨対応）は**各所見行に明示**で持たせる。

### C 構造化データ ＋ サマリ

`findings.csv` / `findings.json`（**1 行 = 1 所見**）＋ `summary.md`（ページ単位スコア表・集計・前回実行との差分＝経時比較用）。**初回実行で前回データが無い場合**は差分欄を `N/A（初回実行）` とするか、同一実行内に比較対象がある場合（例: before / after の 2 URL を評価）はその実行内比較で代替する（差分欄を空欄のまま放置しない）。列と行サンプル：

```
url,category,item,score_or_severity,needs_fix,element,recommendation
https://ex.com/,a11y,画像にalt無し(image-alt),weight 10 (critical),yes,tbody>tr>td>img (33要素),意味画像にalt付与/装飾はalt=""
https://ex.com/,performance,LCP,2.78s (要改善),yes,最大要素,LCP要素をプリロード/画像最適化
https://ex.com/,usability,#1 状態の可視性,severity 3,yes,送信ボタン周辺,処理中インジケータを追加
```

- **1 行の単位**: a11y = 失敗 audit 1 件 ／ performance = CWV メトリック 1 件 ／ usability = ヒューリスティック所見 1 件。
- **Lighthouse のカテゴリ 0-100 スコアは所見ではない** → findings 行に入れず **`summary.md` のページ単位スコア表**に置く（per-page と per-finding の出力先を分ける）。
- **`score_or_severity` の表記**: a11y = `weight N (label)`（label は `critical` / `serious` / `moderate` / `minor`）／ performance = `実測値 (帯)`（**帯は `良好` / `要改善` / `不良` の 3 語に固定**）／ usability = `severity N`。enum 値は表記揺れさせない。
- `category` は `a11y` / `usability` / `performance`。スプレッドシート・BI 取り込みや定点観測向き。

## CSP / 失敗時フォールバック

- **生 `browser_evaluate` で CDN から axe を `<script>` 注入しない**。実サイトの CSP `script-src` でブロックされ沈黙失敗する。a11y 検出は Lighthouse 経由に一本化する（Lighthouse は内部で axe を Chrome に正規注入するため CSP を回避する）。
- Lighthouse が落ちる（認証・ボット対策・タイムアウト）→ そのページは「**定量取得不可**」と理由付きで明記し、MCP snapshot ベースのヒューリスティック評価のみ実施する。
- 認証必須サイト → ユーザーに方法を確認（Lighthouse への Cookie / ヘッダ受け渡し、または対象から除外）。
- Chrome の自動検出が外れる → `CHROME_PATH` 環境変数で実行パスを渡す（例: `CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"`）。
- node / npx / Chrome のいずれも無い → 評価不能を報告し、何が必要かを伝える。
- Playwright MCP が使えない（ブラウザ未導入で install もできない等）→ `chrome-devtools` MCP（`navigate` / `evaluate` / `screenshot`）または `playwright-cli` スキルで snapshot・screenshot・リンク抽出を代替する。手段ごとの取得可否は下表のとおり：

  | 手段 | aria-tree snapshot | screenshot | DOM（evaluate） | リンク抽出 |
  |---|---|---|---|---|
  | Playwright MCP | ○ | ○ | ○ | ○（`a[href]`） |
  | chrome-devtools MCP | ✗ | ○ | ○ | ○（`evaluate` で `a[href]`） |
  | playwright-cli | △（スクリプト次第） | ○ | ○ | ○ |

- **degraded の判定基準（full か degraded か）**: 定性が「degraded」かどうかは**取得できたツールの種類ではなく「Nielsen walk-through を完遂できたか」で決める**。aria-tree snapshot が無くても **screenshot ＋ DOM（evaluate）で画面を walk-through できれば full**（degraded ではない。フォールバック手段を使った旨は手法ノートに 1 行残す）。screenshot も DOM も取れず walk-through 自体が実施不能なときだけ「**定性 degraded**」とレポートに明記する。「特定ツールが揃わない＝即 degraded」と誤読しない。
- リンク抽出が JS レンダリング依存で取れない → `browser_snapshot` の aria tree からリンクを拾う（Playwright MCP 利用時。chrome-devtools 経路では `evaluate` の `a[href]` 抽出で代替）。

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
