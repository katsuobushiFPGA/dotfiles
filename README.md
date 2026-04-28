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

以下が `bootstrap.sh` 内で自動インストールされる：

| ツール | WSL | Mac |
|---|---|---|
| zsh | apt でインストール | 標準搭載（Homebrew がなければ先にインストール） |
| chezmoi | ✅ | ✅ |
| mise | ✅ | ✅ |
| oh-my-zsh | ✅ | ✅ |
| Powerlevel10k | ✅ | ✅ |
| zsh-syntax-highlighting | ✅ | ✅ |
| TPM (tmux plugin manager) | ✅ | ✅ |
| JetBrainsMono Nerd Font | ✅ | ✅ |
| Neovim (最新版) | GitHub Releases から取得 | Brewfile (`brew "neovim"`) |
| Docker | apt でインストール | Brewfile (`cask "docker"`) |
| Brewfile 経由パッケージ（cmux 等） | — | ✅ |
| Claude Code MCP（chrome-devtools, playwright） | ✅ | ✅ |
| Playwright Chromium | ✅ | ✅ |

その他の CLI ツール（ripgrep, fzf, bat, eza, gh, lazygit, difit など）は mise が管理する。詳細は [`dot_config/mise/config.toml.tmpl`](dot_config/mise/config.toml.tmpl) を参照。

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
5. `npx playwright install chromium` — Playwright MCP 用ブラウザを最新化

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
| `dot_gitconfig.tmpl` | `~/.gitconfig` |
| `dot_oh-my-zsh/custom/` | `~/.oh-my-zsh/custom/` |
| `dot_agents/dot_skill-lock.json` | `~/.agents/.skill-lock.json` |
| `dot_config/mise/config.toml.tmpl` | `~/.config/mise/config.toml` |
| `dot_config/nvim/` | `~/.config/nvim/` |
| `dot_config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `dot_config/cmux/cheatsheet.txt` | `~/.config/cmux/cheatsheet.txt` |
| `dot_config/git/ignore` | `~/.config/git/ignore` |
| `dot_config/homebrew/Brewfile` | `~/.config/homebrew/Brewfile`（Macのみ参照） |
| `dot_claude/settings.json` | `~/.claude/settings.json` |
| `dot_claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `dot_claude/hooks/` | `~/.claude/hooks/` |
| `dot_claude/agents/` | `~/.claude/agents/` |
| `dot_claude/skills/` | `~/.claude/skills/` |
| `private_Library/private_Application Support/` | `~/Library/Application Support/`（Macのみ） |

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
| `doc-sync-check.sh` | dotfiles リポジトリで `dot_*` / `bootstrap.sh` をコミットしたのに README/CLAUDE.md が未更新なら警告 |

## Claude Code エージェント

`dot_claude/agents/` に自作エージェント（code-reviewer, doc-reviewer, dev-cycle, programmer, test-debugger, tutor など）を管理している。

一覧・使い分け・追加手順は [`dot_claude/agents/README.md`](dot_claude/agents/README.md) を参照。

## Claude Code スキル

`dot_claude/skills/` に自作スキルを置く。`chezmoi apply` で `~/.claude/skills/` にデプロイされる。

| スキル | 役割 |
|---|---|
| `dev-cycle` | programmer ＋ code-reviewer のサイクルを最大3回回す開発フロー |
| `js-debug` | JS/TS/Next.js のランタイム不具合を Playwright 等で再現・観測して原因特定 |

外部リポジトリからインストールするスキル（`npx skills` 管理）の運用や、自作スキル追加手順は [`dot_claude/CLAUDE.md`](dot_claude/CLAUDE.md) を参照。

## 手動セットアップ

### Chrome 拡張

以下は手動でインストールする：

| 拡張 | リンク |
|---|---|
| React Developer Tools | https://chromewebstore.google.com/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi |
