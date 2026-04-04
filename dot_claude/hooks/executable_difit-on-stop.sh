#!/bin/bash
# git 管理下で、このセッションでファイル変更があった場合に difit で差分を表示する

export PATH="$HOME/.local/share/mise/shims:/usr/local/bin:$PATH"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

FLAG_FILE="${HOME}/.cache/claude-hooks/file-changed-${SESSION_ID}"
[[ -f "$FLAG_FILE" ]] || exit 0
rm -f "$FLAG_FILE"

DIFF_HASH=$(git diff HEAD 2>/dev/null; git status --porcelain 2>/dev/null)
DIFF_HASH=$(echo "$DIFF_HASH" | shasum | cut -d' ' -f1)
HASH_FILE="${HOME}/.cache/claude-hooks/difit-last-hash-$(git rev-parse --show-toplevel | tr '/' '_')"

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  [[ "$(cat "$HASH_FILE" 2>/dev/null)" == "$DIFF_HASH" ]] && exit 0
  echo "$DIFF_HASH" > "$HASH_FILE"
  nohup difit working --include-untracked > /dev/null 2>&1 &
  disown
fi
