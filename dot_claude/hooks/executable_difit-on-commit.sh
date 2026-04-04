#!/bin/bash
# git commit 後に difit を cmux で開く（PostToolUse: Bash 用）

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ "$COMMAND" == *"git commit"* ]] || exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
INITIAL_HEAD_FILE="${HOME}/.cache/claude-hooks/initial-head-${SESSION_ID}"
INITIAL_HEAD=$(cat "$INITIAL_HEAD_FILE" 2>/dev/null)
CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null)

if [[ -n "$INITIAL_HEAD" && "$INITIAL_HEAD" != "$CURRENT_HEAD" ]]; then
  ~/.claude/hooks/difit-open.sh "$INITIAL_HEAD..$CURRENT_HEAD"
else
  ~/.claude/hooks/difit-open.sh HEAD --clean
fi
