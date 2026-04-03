# dotfiles メモ

## スキル管理

### ファイル構成

| パス | 役割 |
|---|---|
| `dotfiles/skills-lock.json` | `npx skills` のロックファイル（chezmoi で `~/skills-lock.json` にデプロイ） |
| `~/.agents/.skill-lock.json` | カスタムスクリプト用ロックファイル（`install-claude-skills` が参照） |
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

スキルの再インストールには2つの仕組みがある：

- **`npx skills` 経由**（推奨）: `skills-lock.json` が dotfiles で管理されており、`npx skills experimental_install` で再インストールできる
- **カスタムスクリプト経由**: `bootstrap.sh` が `bin/install-claude-skills` を呼び出し、`~/.agents/.skill-lock.json` を読んでスキルを再インストールする（別フォーマット）

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
