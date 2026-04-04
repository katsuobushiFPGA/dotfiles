#!/bin/bash
# git 管理下で、このセッションでファイル変更があった場合に difit で差分を表示する

export PATH="$HOME/.local/share/mise/shims:/usr/local/bin:$PATH"

source ~/.claude/hooks/session-lib.sh

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

FLAG_FILE="${CACHE_DIR}/file-changed-${SESSION_ID}"
[[ -f "$FLAG_FILE" ]] || exit 0
rm -f "$FLAG_FILE"

REPO_KEY=$(git rev-parse --show-toplevel | tr '/' '_')
HASH_FILE="${CACHE_DIR}/difit-last-hash-${REPO_KEY}"

INITIAL_HEAD_FILE="${CACHE_DIR}/initial-head-${SESSION_ID}"
INITIAL_HEAD=$(cat "$INITIAL_HEAD_FILE" 2>/dev/null)
CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null)
rm -f "$INITIAL_HEAD_FILE"

CURRENT_STATE=$(echo "$CURRENT_HEAD"; git diff HEAD 2>/dev/null; git status --porcelain 2>/dev/null)
CURRENT_HASH=$(echo "$CURRENT_STATE" | shasum | cut -d' ' -f1)

[[ "$(cat "$HASH_FILE" 2>/dev/null)" == "$CURRENT_HASH" ]] && exit 0

if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  ~/.claude/hooks/difit-open.sh working --include-untracked
elif [[ -n "$INITIAL_HEAD" && "$INITIAL_HEAD" != "$CURRENT_HEAD" ]]; then
  ~/.claude/hooks/difit-open.sh "$INITIAL_HEAD" "$CURRENT_HEAD"
else
  exit 0
fi

echo "$CURRENT_HASH" > "$HASH_FILE"
