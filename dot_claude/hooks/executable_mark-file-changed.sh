#!/bin/bash
# Write/Edit ツール使用時にセッションフラグを立てる

source ~/.claude/hooks/session-lib.sh

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[[ -z "$SESSION_ID" ]] && exit 0
[[ -n "$CWD" ]] && cd "$CWD" 2>/dev/null

case "$TOOL_NAME" in
  Write|Edit|NotebookEdit|Bash)
    mkdir -p "$CACHE_DIR"
    touch "${CACHE_DIR}/file-changed-${SESSION_ID}"
    # セッション開始時の HEAD を初回のみ記録
    INITIAL_HEAD_FILE="${CACHE_DIR}/initial-head-${SESSION_ID}"
    if [[ ! -f "$INITIAL_HEAD_FILE" ]]; then
      git rev-parse HEAD 2>/dev/null > "$INITIAL_HEAD_FILE"
    fi
    ;;
esac
