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

CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null)
INITIAL_HEAD_FILE="${HOME}/.cache/claude-hooks/initial-head-${SESSION_ID}"
INITIAL_HEAD=$(cat "$INITIAL_HEAD_FILE" 2>/dev/null)
rm -f "$INITIAL_HEAD_FILE"

CURRENT_STATE=$(echo "$CURRENT_HEAD"; git diff HEAD 2>/dev/null; git status --porcelain 2>/dev/null)
CURRENT_HASH=$(echo "$CURRENT_STATE" | shasum | cut -d' ' -f1)

[[ "$(cat "$HASH_FILE" 2>/dev/null)" == "$CURRENT_HASH" ]] && exit 0
echo "$CURRENT_HASH" > "$HASH_FILE"

launch_difit() {
  local TMPFILE
  TMPFILE=$(mktemp)
  nohup difit "$@" --no-open > "$TMPFILE" 2>&1 &
  disown

  local URL
  for _ in $(seq 1 20); do
    URL=$(grep -o 'http://localhost:[0-9]*' "$TMPFILE" 2>/dev/null | head -1)
    [[ -n "$URL" ]] && break
    sleep 0.2
  done
  rm -f "$TMPFILE"

  if [[ -n "$URL" ]]; then
    if cmux browser open "$URL" 2>/dev/null; then
      : # cmux で開いた
    elif grep -qi microsoft /proc/version 2>/dev/null; then
      explorer.exe "$URL" 2>/dev/null || true
    fi
  fi
}

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  launch_difit working --include-untracked
elif [[ -n "$INITIAL_HEAD" && "$INITIAL_HEAD" != "$CURRENT_HEAD" ]]; then
  launch_difit "$INITIAL_HEAD..$CURRENT_HEAD"
else
  exit 0
fi
