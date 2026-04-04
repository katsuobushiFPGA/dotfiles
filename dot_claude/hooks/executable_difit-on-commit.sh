#!/bin/bash
# git commit 後に difit を cmux で開く（PostToolUse: Bash 用）

source ~/.claude/hooks/session-lib.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ "$COMMAND" == *"git commit"* ]] || exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
DIFF_ARGS=$(session_diff_args "$SESSION_ID")

if [[ -n "$DIFF_ARGS" ]]; then
  ~/.claude/hooks/difit-open.sh "$DIFF_ARGS"
else
  ~/.claude/hooks/difit-open.sh HEAD --clean
fi
