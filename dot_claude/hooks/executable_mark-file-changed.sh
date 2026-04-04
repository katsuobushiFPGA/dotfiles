#!/bin/bash
# Write/Edit ツール使用時にセッションフラグを立てる

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

[[ -z "$SESSION_ID" ]] && exit 0

case "$TOOL_NAME" in
  Write|Edit|NotebookEdit|Bash)
    mkdir -p "${HOME}/.cache/claude-hooks"
    touch "${HOME}/.cache/claude-hooks/file-changed-${SESSION_ID}"
    # セッション開始時の HEAD を初回のみ記録
    INITIAL_HEAD_FILE="${HOME}/.cache/claude-hooks/initial-head-${SESSION_ID}"
    if [[ ! -f "$INITIAL_HEAD_FILE" ]]; then
      git rev-parse HEAD 2>/dev/null > "$INITIAL_HEAD_FILE"
    fi
    ;;
esac
