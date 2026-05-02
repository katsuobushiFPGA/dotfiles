# Claude Code グローバル設定

## コード修正時の自動レビューループ

実装系のコードを書いた／修正したときは、**一連の実装タスクが終わった時点（コミット候補が固まったタイミング）** で必ず以下を回す：

1. `code-reviewer` エージェントを起動して差分をレビューさせる
2. 🔴 指摘があれば自分で修正し、再度 `code-reviewer` に投げる
3. 🔴 が無くなるまで繰り返す（**最大 10 回**で打ち切り。10 回を超えても残るならユーザーに状況を報告して相談）

**Why**: セルフレビューでは抜けやすい問題を別視点で拾うため。レビュー観点が偏らないよう、実装と同じセッションで自動化する。

**ファイル種別ごとの呼び分け**:
| 主な変更内容 | 呼ぶエージェント |
|---|---|
| 実装コード（.ts/.tsx/.js/.py/.go/.rb/.rs/.sh など） | `code-reviewer` |
| ドキュメントのみ（.md） | `doc-reviewer` |
| 設計書・RFC のみ | `system-design-reviewer` |
| エージェント定義ファイルのみ | `agent-doc-reviewer` |

**スコープ**: 全プロジェクト共通ルール。プロジェクト固有の `CLAUDE.md` で明示的に上書き／無効化されていない限り適用する。

---

## レビュー後の動作確認

🔴 指摘がなくなって `code-reviewer` のループを抜けたら、**コミット／報告の前に実際にユースケースを軽く流して動作確認する**。

**やること**:
- 追加・変更した機能の代表的なコマンドを実行して、エラーなく期待どおりに動くことを確認する（CLI なら `--help` だけでなく実ユースケース 1 回、関数なら呼び出し例 1 回、UI なら主要画面を 1 度操作する、など）
- 設定ファイルを書き換えた場合は反映コマンド（`chezmoi apply` / `mise install` / `source ~/.zshrc` 相当）まで実行して、想定どおり読み込まれるかを確認する
- 失敗したら修正 → `code-reviewer` 再レビュー → 動作確認、のループに戻す

**対象外**:
- ドキュメントのみの変更（README、CLAUDE.md、設計書、コメント追記など）
- 実行環境を持たない変更（リネーム、import の整理、型注釈の追記のみ など、挙動に影響しないもの）

**Why**: レビューはコード品質の担保で、動作するかは別問題。ビルドが通ること・テストが緑であることと、実際に手で触って動くことは別物なので、コミット前に最低 1 回は実機で叩いて確認する。

---

## ドキュメント整合性ルール

以下のファイルを変更したときは、対応するドキュメントを **同じコミット** に含めて更新する。READMEとコードの乖離は再現性とオンボーディングを壊すので、後回しにしない。

| 変更したもの | 連動して見直すドキュメント |
|---|---|
| `dot_config/mise/config.toml.tmpl` のツール追加・削除 | `README.md` のインストール表（個別インストール対象が増減する場合） |
| chezmoi 管理ファイル（`dot_*` / `private_*`）の追加・移動・削除 | `README.md` の「管理対象のファイル」表 |
| `bootstrap.sh` の手順変更 | `README.md` のセットアップ手順、必要なら「ツール表」 |
| `dot_claude/hooks/` のフック追加・削除・役割変更 | `README.md` の「Claude Code フック」表、`dot_claude/CLAUDE.md` の difit セクション |
| `dot_claude/agents/` `dot_claude/skills/` の追加・削除 | 外部スキルなら `dot_agents/dot_skill-lock.json` か `dot_apm/apm.yml`+`dot_apm/apm.lock.yaml`、特殊な使い方なら `dot_claude/CLAUDE.md` |
| `dot_config/homebrew/Brewfile` のパッケージ追加・削除 | `README.md` のインストール表（注目すべきものなら） |
| apm 経由スキルの追加・削除（`apm install -g ...`） | `~/.apm/apm.yml` と `~/.apm/apm.lock.yaml` を `dot_apm/` にコピー、`README.md` の管理対象表は変更不要 |

**運用方針**:
- ファイル編集後にドキュメントを `grep` して言及箇所を確認する。
- ドキュメント更新を別PR/別コミットに分けない（レビュー時に乖離が見えにくくなるため）。
- 「ドキュメントに書くほどでもない軽微な変更」と判断したら、その理由をコミットメッセージに残す。

## スキル管理

外部スキルは `npx skills` と apm の 2 系統で管理している。両方とも最終的には `~/.claude/skills/<name>` に配置されるが、実体の置き場と再インストール手段が異なる。

### 新規スキル追加時の選択ルール

- **upstream が apm 配布に対応している場合は apm でインストールする**（マニフェスト + ロックの再現性、依存解決、`apm audit` などのメリットがあるため）
- **upstream が `npx skills` 配布のみを想定している場合は `npx skills` でインストールする**（mattpocock/skills, vercel-labs/skills など）

> NOTE: 将来 apm か `npx skills` のどちらかがエコシステムの標準になったら、もう片方を畳んで一本化する。今は両系統を並走させる。

### ファイル構成

#### 共通

| パス | 役割 |
|---|---|
| `~/.claude/skills/<name>` | Claude Code が読むスキル本体。`npx skills` 系はシンボリックリンク、apm 系は実体ディレクトリ、自作は単一 `.md` |
| `dotfiles/dot_claude/skills/<name>.md` | 自作スキル（chezmoi で `~/.claude/skills/` に直接デプロイ） |

#### `npx skills` 系（mattpocock/skills, vercel-labs/skills など）

| パス | 役割 |
|---|---|
| `~/.agents/.skill-lock.json` | ロックファイル（`dot_agents/dot_skill-lock.json` から chezmoi でデプロイ） |
| `~/.agents/skills/<name>/` | スキルの実体 |
| `~/.claude/skills/<name>` | `../../.agents/skills/<name>` へのシンボリックリンク |

#### apm 系（mizchi/skills など、apm 配布が推奨されているもの）

| パス | 役割 |
|---|---|
| `~/.apm/apm.yml` | マニフェスト（`dot_apm/apm.yml` から chezmoi でデプロイ） |
| `~/.apm/apm.lock.yaml` | ロックファイル（`dot_apm/apm.lock.yaml` から chezmoi でデプロイ） |
| `~/.apm/apm_modules/<owner>/<repo>/` | スキルの実体（apm のキャッシュ。chezmoi では管理しない） |
| `~/.claude/skills/<name>` | apm がデプロイしたスキルの実体ディレクトリ |
| `~/.config/opencode/skills/<name>`, `~/.copilot/skills/<name>`, `~/.gemini/skills/<name>` | apm が他 AI ツール向けにも自動配置（`includes: auto` の挙動）。Claude Code からは参照しないが配置はされる |

> **同名スキルを `npx skills` 系と apm 系の両方で管理しない**。`~/.claude/skills/<name>` の上書き順序は bootstrap.sh の実行順（npx skills → apm）に依存し、症状が分かりにくいため、どちらか一方に統一する。

### 外部リポジトリからスキルを追加する

#### `npx skills` の場合

```bash
# ~/.agents/ 配下から実行すること（カレントディレクトリに .agents/ が作られる）
cd ~
npx skills add https://github.com/<owner>/<repo> --skill <skill-name> --yes
```

**注意**: dotfiles ディレクトリで実行すると `dotfiles/.agents/` にインストールされてしまう。  
その場合は手動で移動する：

```bash
mv ~/dotfiles/.agents/skills/<name> ~/.agents/skills/<name>
ln -snf "../../.agents/skills/<name>" ~/.claude/skills/<name>
rmdir ~/dotfiles/.agents/skills ~/dotfiles/.agents
```

シンボリックリンクが作られなかった場合も同様に手動で作成する。

#### apm の場合

```bash
# ~/ から実行すること（apm が CWD を project root として扱うため）
cd ~
apm install -g <owner>/<repo>/<skill-name>
# 例: apm install -g mizchi/skills/empirical-prompt-tuning
```

インストール後に `~/.apm/apm.yml` と `~/.apm/apm.lock.yaml` が更新される。dotfiles 側に反映するには：

```bash
cp ~/.apm/apm.yml ~/dotfiles/dot_apm/apm.yml
cp ~/.apm/apm.lock.yaml ~/dotfiles/dot_apm/apm.lock.yaml

# resolved_commit が変わっているか確認（generated_at だけの差分はコミット不要）
git -C ~/dotfiles diff dot_apm/apm.lock.yaml
```

`apm.yml` には `name`, `version`, `author` などのプロジェクトメタが含まれるが、`-g`（user scope）専用なので個人情報として割り切ってコミットする。`apm.lock.yaml` の `generated_at` はインストール時刻が入るため、依存に変更がないときはタイムスタンプ差分しか出ない（=コミット不要）。

### 新しい環境での再現

bootstrap.sh が両方の系統を自動で復元する：

- `~/.agents/.skill-lock.json` があれば `npx skills experimental_install`
- `~/.apm/apm.yml` があれば `apm install -g`

手動で再実行する場合も同じコマンド（必ず `$HOME` で実行する。`apm` も `npx skills` も CWD 配下に作業ディレクトリを作るため）。

### 自作スキルを追加する

`dotfiles/dot_claude/skills/<name>.md` を作成して `chezmoi apply` するだけ。

```bash
# 作成
vim ~/dotfiles/dot_claude/skills/my-skill.md

# 反映
chezmoi apply ~/.claude/skills/my-skill.md
```

---

## difit

git 差分を GitHub 風ビューアで確認できる CLI。

- mise 管理の npm でグローバルインストール済み
- `--comment` オプションは **v4 以降**が必要（v3 では使えない）
- バージョン確認: `difit --version`
- アップグレード: `npm install -g difit@latest`

`/difit-review` スキルで差分レビュー＋コメント付き起動ができる。

### Claude Code フック連携

| フック | タイミング | 動作 |
|---|---|---|
| `difit-on-commit.sh` | PostToolUse (Bash) | コマンド中に `git commit` が含まれると起動。セッション開始時の HEAD から現在 HEAD までの全差分を表示 |
| `difit-on-stop.sh` | Stop | ファイル変更があったセッション終了時に起動。未コミット変更があれば working diff、コミット済みならセッション全差分を表示 |

**セッション差分の仕組み：**  
`mark-file-changed.sh`（PostToolUse）が初回ツール使用時に `INITIAL_HEAD` をキャッシュに記録し、  
コミット・セッション終了時に `INITIAL_HEAD..CURRENT_HEAD` の範囲で difit を起動する。

---

## Agent Teams

Agent Teams（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`）を使う場合、tmux セッション内であれば split panes を優先して使うこと。
