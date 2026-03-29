#!/bin/bash
# git 管理下で、このセッションでファイル変更があった場合に difit で差分を表示する

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

FLAG_FILE="/tmp/claude-file-changed-${SESSION_ID}"
[[ -f "$FLAG_FILE" ]] || exit 0
rm -f "$FLAG_FILE"

if ! git diff --quiet 2>/dev/null || ! git diff --staged --quiet 2>/dev/null; then
  nohup difit HEAD > /dev/null 2>&1 &
  disown
fi
