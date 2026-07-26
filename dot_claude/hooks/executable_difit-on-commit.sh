#!/bin/bash
# git commit 後に difit を cmux で開く（PostToolUse: Bash 用）

# shellcheck source=/dev/null
source ~/.claude/hooks/session-lib.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ "$COMMAND" == *"git commit"* ]] || exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
# CWD が指定されていて cd に失敗したら安全に抜ける（フックの cwd は不安定なため）
[[ -n "$CWD" ]] && { cd "$CWD" 2>/dev/null || exit 0; }
DIFF_ARGS=$(session_diff_args "$SESSION_ID")

if [[ -n "$DIFF_ARGS" ]]; then
  # shellcheck disable=SC2086
  ~/.claude/hooks/difit-open.sh $DIFF_ARGS
else
  ~/.claude/hooks/difit-open.sh HEAD --clean
fi
