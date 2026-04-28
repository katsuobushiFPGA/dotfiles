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

## ドキュメント整合性ルール

以下のファイルを変更したときは、対応するドキュメントを **同じコミット** に含めて更新する。READMEとコードの乖離は再現性とオンボーディングを壊すので、後回しにしない。

| 変更したもの | 連動して見直すドキュメント |
|---|---|
| `dot_config/mise/config.toml.tmpl` のツール追加・削除 | `README.md` のインストール表（個別インストール対象が増減する場合） |
| chezmoi 管理ファイル（`dot_*` / `private_*`）の追加・移動・削除 | `README.md` の「管理対象のファイル」表 |
| `bootstrap.sh` の手順変更 | `README.md` のセットアップ手順、必要なら「ツール表」 |
| `dot_claude/hooks/` のフック追加・削除・役割変更 | `README.md` の「Claude Code フック」表、`dot_claude/CLAUDE.md` の difit セクション |
| `dot_claude/agents/` `dot_claude/skills/` の追加・削除 | 外部スキルなら `dot_agents/dot_skill-lock.json`、特殊な使い方なら `dot_claude/CLAUDE.md` |
| `dot_config/homebrew/Brewfile` のパッケージ追加・削除 | `README.md` のインストール表（注目すべきものなら） |

**運用方針**:
- ファイル編集後にドキュメントを `grep` して言及箇所を確認する。
- ドキュメント更新を別PR/別コミットに分けない（レビュー時に乖離が見えにくくなるため）。
- 「ドキュメントに書くほどでもない軽微な変更」と判断したら、その理由をコミットメッセージに残す。

## スキル管理

### ファイル構成

| パス | 役割 |
|---|---|
| `~/.agents/.skill-lock.json` | `npx skills` のロックファイル（`dot_agents/dot_skill-lock.json` から chezmoi でデプロイ） |
| `~/.agents/skills/<name>/` | スキルの実体（外部リポジトリからインストール） |
| `~/.claude/skills/<name>` | `../../.agents/skills/<name>` へのシンボリックリンク |
| `dotfiles/dot_claude/skills/<name>.md` | 自作スキル（chezmoi で `~/.claude/skills/` に直接デプロイ） |

### 外部リポジトリからスキルを追加する

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

### 新しい環境での再現

`dot_agents/dot_skill-lock.json` を dotfiles の git で管理しており、新しい環境では `bootstrap.sh` が `npx skills experimental_install` を呼び出して `~/.agents/.skill-lock.json` を読み再インストールする。

手動で再実行したい場合も同じコマンドでよい（`$HOME` で実行すること。CWD 配下に `.agents/` を作らないため）。

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
