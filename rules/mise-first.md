# mise 優先ルール

CLI ツール／ランタイム／言語処理系を新たに dotfiles に組み込むときは、**mise の registry にエントリがあれば mise でインストールする**。手書きの `curl | sh` や apt / brew への直書きは「mise で扱えない」と確認できた場合の最終手段。

## 手順

1. `mise registry | grep -iE '^<tool>\b'` で登録があるか確認（`-E` がないと `\b` の word-boundary が効かない）
2. あれば `dot_config/mise/config.toml.tmpl` の `[tools]` 配下に `<tool> = "latest"`（必要ならバージョン固定）を追加
3. `chezmoi apply ~/.config/mise/config.toml && mise install` で反映
4. `README.md` の「mise が管理する CLI ツール」一覧に追記
5. 既存の install 経路を **全 OS 分** 削除する。確認対象は最低でも以下:
   - `bootstrap.sh` の `curl ... | sh` / `tar` 展開 / GitHub Releases 取得
   - `bootstrap.sh` の `sudo apt-get install`
   - `dot_config/homebrew/Brewfile` の `brew "<tool>"` / `cask "<tool>"`
   同時に過去環境向け片付けブロックを追加（次節「移行時の注意」を参照）

## Why

一貫管理のメリット — `mise upgrade` で全ツール一括更新、バージョン固定で再現性、`~/.local/share/mise/shims` に PATH を集約してクリーン。bootstrap.sh の手書き install ブロックが減ると、新環境セットアップでの失敗ポイントも減る。

## 例外（mise 経由にしないもの）

- mise registry に存在しない、または存在しても上流が壊れている／古い
- mise 自身（chicken-and-egg。`bootstrap.sh` で `mise.run` を curl）
- chezmoi（mise install より前に動く必要がある）
- システムパッケージ（apt / brew で入れるもの: docker, fontconfig, zsh, curl 等）
- npm スキル（`npx skills` 系）と apm スキル（個別エコシステムで管理）

例外で手書きインストールにするときは `bootstrap.sh` のコメントで理由を残す。

## 移行時の注意（PATH の優先順位）

`bootstrap.sh` 冒頭の PATH:

```bash
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
```

`~/.local/bin` が **mise shim より優先** される。手書きインストール → mise 管理に切り替えるときは、過去に `~/.local/bin/<tool>` を入れた環境で古いバイナリが mise shim を隠してしまう。`bootstrap.sh` に「mise shim が存在することを確認してから古いバイナリを削除」する片付けブロックを必ず追加する。

片付けブロックを書くときの **対象列挙ルール**:

- 旧 installer が配置した **すべてのパス** を列挙する。`tar -C ... --strip-components=N` のような展開系は `bin/`, `share/<tool>/`, `lib/<tool>/`, `share/man/man*/<tool>.*` 等に複数撒くので、すべて `rm -f` / `rm -rf` する。配置パスは旧コマンドの引数から逆引きする
- Mac で `brew install` 経由だった場合は `brew uninstall` ではなく **Brewfile から行を落とす** で十分（次回 `brew bundle cleanup` で消える。即時に PATH 衝突を解消したい人向けに `brew unlink <tool>` を案内してもよい）
- 削除は **必ず** `[[ -L "$HOME/.local/share/mise/shims/<tool>" ]]` で mise shim の存在を確認してから（shim が無い環境を壊さないため）
