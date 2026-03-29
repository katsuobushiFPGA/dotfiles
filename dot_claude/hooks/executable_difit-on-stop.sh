#!/bin/bash
# git 管理下で、このセッションでファイル変更があった場合に difit で差分を表示する

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# トランスクリプトから Write/Edit の使用を確認
[[ -f "$TRANSCRIPT_PATH" ]] || exit 0
grep -q '"name":"Write"\|"name":"Edit"\|"name":"NotebookEdit"' "$TRANSCRIPT_PATH" 2>/dev/null || exit 0

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  nohup difit working --include-untracked > /dev/null 2>&1 &
  disown
fi
