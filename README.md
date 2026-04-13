# dotfiles

WSL / Mac 対応のdotfiles。[chezmoi](https://www.chezmoi.io/) で管理し、[mise](https://mise.jdx.dev/) でツールのバージョンを管理する。

## セットアップ

### 1. このリポジトリをclone

```bash
git clone <このリポジトリのURL> ~/dotfiles
```

### 2. bootstrap.shを実行

```bash
cd ~/dotfiles
bash bootstrap.sh
```

以下が自動インストールされる：

| ツール | WSL | Mac |
|---|---|---|
| zsh | apt でインストール | 標準搭載（Homebrew がなければ先にインストール） |
| chezmoi | ✅ | ✅ |
| mise | ✅ | ✅ |
| oh-my-zsh | ✅ | ✅ |
| Neovim (最新版) | GitHub Releases から取得 | `brew install neovim` |
| cmux | — | `brew install cmux` |
| Powerlevel10k | ✅ | ✅ |
| difit | ✅ | ✅ |

### 3. chezmoiで設定を反映

```bash
chezmoi init --source ~/dotfiles
chezmoi apply
```

### 4. デフォルトシェルをzshに変更

```bash
chsh -s $(which zsh)
```

### 5. プロンプトの設定

Powerlevel10k のプロンプトを設定する：

```bash
p10k configure
```

## 更新

dotfiles や各ツールを最新化するときは `mise run update` を使う。

```bash
mise run update
```

以下を順番に実行する：

1. `git pull` — dotfiles リポジトリを最新化
2. `chezmoi apply` — 設定ファイルをホームディレクトリに反映
3. `mise upgrade` — mise 管理ツールを一括アップグレード
4. `npx skills experimental_install` — Claude スキルを再インストール

### dotfiles だけ反映したい場合

ツールのアップグレードは不要で、設定ファイルだけ反映したいときは：

```bash
git pull
chezmoi apply
```

## タスクランナー（mise tasks）

mise の task 機能でよく使う操作をまとめている。

| コマンド | 内容 |
|---|---|
| `mise run init` | 初回セットアップ（bootstrap.sh を実行） |
| `mise run update` | dotfiles・ツール一括アップデート |

## 管理対象のファイル

| dotfilesのパス | 展開先 |
|---|---|
| `dot_zshrc.tmpl` | `~/.zshrc` |
| `dot_zprofile` | `~/.zprofile` |
| `dot_config/mise/config.toml` | `~/.config/mise/config.toml` |
| `dot_config/nvim/` | `~/.config/nvim/` |
| `dot_config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `dot_claude/settings.json` | `~/.claude/settings.json` |
| `dot_claude/hooks/` | `~/.claude/hooks/` |
| `dot_claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |

## OS差分

`dot_zshrc.tmpl` はchezmoiのテンプレート機能でOS別に設定を切り替える。

**WSL のみ適用：**
- Google Cloud SDK
- `LIBGL_ALWAYS_SOFTWARE=1`
- opencode / go の PATH

**Mac のみ適用：**
- Homebrew の初期化（Apple Silicon / Intel 両対応）

## Claude Code フック

`dot_claude/hooks/` に Claude Code の PostToolUse / Stop フックを管理している。

| フック | 役割 |
|---|---|
| `difit-on-commit.sh` | `git commit` を含むコマンド実行後、セッション全差分を difit で表示 |
| `difit-on-stop.sh` | セッション終了時、変更があれば差分を difit で表示 |
| `difit-open.sh` | difit を cmux 内蔵ブラウザ（または WSL フォールバック）で開く共通スクリプト |
| `mark-file-changed.sh` | ツール使用時にセッションフラグとセッション開始 HEAD を記録 |

## 手動セットアップ

### Chrome 拡張

以下は手動でインストールする：

| 拡張 | リンク |
|---|---|
| React Developer Tools | https://chromewebstore.google.com/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi |

## ツールバージョン（mise管理）

`~/.config/mise/config.toml` で管理：

```toml
[tools]
node    = "22"
go      = "1.22"
ripgrep = "latest"  # telescope live_grep に必要
fd      = "latest"  # telescope find_files を高速化
fzf     = "latest"  # fuzzy history検索（Ctrl+R強化）
bat     = "latest"  # cat の代替（シンタックスハイライト）
eza     = "latest"  # ls の代替
zoxide  = "latest"  # z コマンドでディレクトリジャンプ
gh      = "latest"  # GitHub CLI
```
