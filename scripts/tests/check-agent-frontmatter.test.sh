#!/usr/bin/env bash
# scripts/check-agent-frontmatter のテスト。
# 一時ディレクトリにエージェント定義を作り、終了コードとエラーメッセージを確かめる。
set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/../check-agent-frontmatter"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

# write_agent <dir> <file> <frontmatter の中身>
write_agent() {
  mkdir -p "$1"
  printf -- '---\n%s\n---\n\n本文。\n' "$3" >"$1/$2"
}

# expect_ok <テスト名> <dir>
expect_ok() {
  local out
  if out="$("$TARGET" "$2" 2>&1)"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL: %s\n  終了コード 0 を期待したが失敗した\n  出力: %s\n' "$1" "$out"
  fi
}

# expect_error <テスト名> <dir> <出力に含まれるべき文字列>
expect_error() {
  local out
  if out="$("$TARGET" "$2" 2>&1)"; then
    fail=$((fail + 1))
    printf 'FAIL: %s\n  非 0 の終了コードを期待したが成功した\n' "$1"
  elif [[ "$out" != *"$3"* ]]; then
    fail=$((fail + 1))
    printf 'FAIL: %s\n  出力に "%s" が含まれない\n  出力: %s\n' "$1" "$3" "$out"
  else
    pass=$((pass + 1))
  fi
}

VALID='name: sample
description: "サンプル。コード変更後に使う。"
model: opus
effort: medium
color: blue
memory: user'

d="$WORK/valid"
write_agent "$d" sample.md "$VALID"
expect_ok "有効な定義は通る" "$d"

d="$WORK/minimal"
write_agent "$d" sample.md 'name: sample
description: 必須フィールドだけ'
expect_ok "name と description だけでも通る" "$d"

d="$WORK/models"
write_agent "$d" a.md 'name: a
description: x
model: fable'
write_agent "$d" b.md 'name: b
description: x
model: inherit'
write_agent "$d" c.md 'name: c
description: x
model: claude-opus-5-5'
write_agent "$d" d.md 'name: d
description: x
model: haiku  # 軽い作業向け'
expect_ok "エイリアス・inherit・フル ID・行末コメント付きの model は通る" "$d"

d="$WORK/readme"
write_agent "$d" sample.md "$VALID"
printf '# 一覧\n\nfrontmatter のない説明用ファイル。\n' >"$d/README.md"
expect_ok "README.md は検査しない" "$d"

d="$WORK/bad-model"
write_agent "$d" sample.md 'name: sample
description: x
model: gpt-4'
expect_error "無効な model を検出する" "$d" "model の値が無効"

d="$WORK/bad-effort"
write_agent "$d" sample.md 'name: sample
description: x
effort: ultra'
expect_error "無効な effort を検出する" "$d" "effort の値が無効"

d="$WORK/bad-color"
write_agent "$d" sample.md 'name: sample
description: x
color: magenta'
expect_error "無効な color を検出する" "$d" "color の値が無効"

d="$WORK/bad-memory"
write_agent "$d" sample.md 'name: sample
description: x
memory: global'
expect_error "無効な memory を検出する" "$d" "memory の値が無効"

d="$WORK/no-name"
write_agent "$d" sample.md 'description: x'
expect_error "name の欠落を検出する" "$d" "name がありません"

d="$WORK/no-description"
write_agent "$d" sample.md 'name: sample'
expect_error "description の欠落を検出する" "$d" "description がありません"

d="$WORK/unknown-field"
write_agent "$d" sample.md 'name: sample
description: x
max_turns: 5'
expect_error "未知のフィールド名を検出する" "$d" "未知のフィールドです: max_turns"

d="$WORK/no-frontmatter"
mkdir -p "$d"
printf '本文だけのファイル。\n' >"$d/sample.md"
expect_error "frontmatter がないファイルを検出する" "$d" "frontmatter がありません"

d="$WORK/multi"
write_agent "$d" good.md "$VALID"
write_agent "$d" bad.md 'name: bad
description: x
color: teal'
expect_error "複数ファイルのうち不正なファイル名を報告する" "$d" "bad.md: color の値が無効"

d="$WORK/quoted-value"
write_agent "$d" sample.md 'name: "sample"
description: "説明 # これはコメントではない"
model: "opus"
color: '"'"'blue'"'"''
expect_ok "引用符で囲んだ値は通る" "$d"

d="$WORK/continued-description"
write_agent "$d" sample.md 'name: sample
description:
  次の行に書いた説明'
expect_ok "値を次の行に書いた description は通る" "$d"

d="$WORK/crlf"
mkdir -p "$d"
printf -- '---\r\nname: sample\r\ndescription: x\r\ncolor: blue\r\n---\r\n\r\n本文。\r\n' >"$d/sample.md"
expect_ok "改行が CRLF のファイルは通る" "$d"

d="$WORK/no-space-after-colon"
write_agent "$d" sample.md 'name:sample
description: x'
expect_error "コロンの後に空白がない行はキーとして扱わない" "$d" "name がありません"

d="$WORK/space-before-colon"
write_agent "$d" sample.md 'name: sample
description: x
model : bogus'
expect_error "コロンの前に空白があるキーも検査する" "$d" "model の値が無効"

d="$WORK/quoted-key"
write_agent "$d" sample.md 'name: sample
description: x
"modell": opus'
expect_error "引用符で囲んだ未知のキーを検出する" "$d" "未知のフィールドです: modell"

d="$WORK/unclosed"
mkdir -p "$d"
printf -- '---\nname: sample\ndescription: x\n\n本文。\n' >"$d/sample.md"
expect_error "閉じる --- がないファイルを検出する" "$d" "閉じる --- が見つからない"

d="$WORK/empty-name"
write_agent "$d" sample.md 'name: ""
description: x'
expect_error "空文字の name を検出する" "$d" "name がありません"

d="$WORK/two-problems"
write_agent "$d" sample.md 'name: sample
description: x
color: teal
effort: ultra'
expect_error "1 ファイルに複数の問題があれば件数を報告する" "$d" "2 件の問題"

d="$WORK/empty-dir"
mkdir -p "$d"
expect_error "定義が 1 件もないディレクトリはエラーにする" "$d" "エージェント定義が見つかりません"

expect_error "存在しないディレクトリはエラーにする" "$WORK/does-not-exist" "ディレクトリがありません"

printf '%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
