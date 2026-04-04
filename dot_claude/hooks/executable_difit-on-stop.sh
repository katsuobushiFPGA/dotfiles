#!/bin/bash
# git 管理下で、このセッションでファイル変更があった場合に difit で差分を表示する

export PATH="$HOME/.local/share/mise/shims:/usr/local/bin:$PATH"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

FLAG_FILE="${HOME}/.cache/claude-hooks/file-changed-${SESSION_ID}"
[[ -f "$FLAG_FILE" ]] || exit 0
rm -f "$FLAG_FILE"

REPO_KEY=$(git rev-parse --show-toplevel | tr '/' '_')
HASH_FILE="${HOME}/.cache/claude-hooks/difit-last-hash-${REPO_KEY}"

CURRENT_STATE=$(git rev-parse HEAD 2>/dev/null; git diff HEAD 2>/dev/null; git status --porcelain 2>/dev/null)
CURRENT_HASH=$(echo "$CURRENT_STATE" | shasum | cut -d' ' -f1)

[[ "$(cat "$HASH_FILE" 2>/dev/null)" == "$CURRENT_HASH" ]] && exit 0
echo "$CURRENT_HASH" > "$HASH_FILE"

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  nohup difit working --include-untracked > /dev/null 2>&1 &
else
  nohup difit HEAD > /dev/null 2>&1 &
fi
disown
