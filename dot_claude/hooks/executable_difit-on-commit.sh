#!/bin/bash
# git commit 後に difit を cmux で開く（PostToolUse: Bash 用）

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ "$COMMAND" == git\ commit* ]] || exit 0

~/.claude/hooks/difit-open.sh HEAD --clean
