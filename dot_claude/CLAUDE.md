# dotfiles メモ

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

`dot_agents/dot_skill-lock.json` を dotfiles の git で管理しており、新しい環境では `bootstrap.sh` が `bin/install-claude-skills` を呼び出して `~/.agents/.skill-lock.json` を読み再インストールする。

`npx skills experimental_install` でも同様に再インストールできる。

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
