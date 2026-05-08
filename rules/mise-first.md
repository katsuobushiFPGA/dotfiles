# mise 優先ルール

CLI ツール／ランタイム／言語処理系を新たに dotfiles に組み込むときは、**mise の registry にエントリがあれば mise でインストールする**。手書きの `curl | sh` や apt / brew への直書きは「mise で扱えない」と確認できた場合の最終手段。

## 手順

1. `mise registry | grep -i '^<tool>\b'` で登録があるか確認
2. あれば `dot_config/mise/config.toml.tmpl` の `[tools]` 配下に `<tool> = "latest"`（必要ならバージョン固定）を追加
3. `chezmoi apply ~/.config/mise/config.toml && mise install` で反映
4. `README.md` の「mise が管理する CLI ツール」一覧に追記
5. 既存の手書き install ブロック（`bootstrap.sh` の `curl ... | sh` など）があれば削除し、過去環境向けに古いバイナリを片付けるブロックも追加

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
