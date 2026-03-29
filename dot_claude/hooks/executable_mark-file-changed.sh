#!/bin/bash
# Write/Edit ツール使用時にセッションフラグを立てる

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

[[ -z "$SESSION_ID" ]] && exit 0

case "$TOOL_NAME" in
  Write|Edit|NotebookEdit)
    mkdir -p "${HOME}/.cache/claude-hooks"
    touch "${HOME}/.cache/claude-hooks/file-changed-${SESSION_ID}"
    ;;
esac
