#!/bin/bash
# dotfiles リポジトリで「ドキュメント連動が必要なファイル」がコミットされたが
# README.md / dot_claude/CLAUDE.md が同じセッションで更新されていない場合に警告する。
# PostToolUse: Bash 用。非ブロッキング（常に exit 0）。

source ~/.claude/hooks/session-lib.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ "$COMMAND" == *"git commit"* ]] || exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
# CWD が指定されていて cd に失敗した場合は安全に抜ける（フックの cwd は不安定なため）
if [[ -n "$CWD" ]]; then
  cd "$CWD" 2>/dev/null || exit 0
fi

# dotfiles リポジトリ判定（remote URL の末尾が /dotfiles。another-dotfiles 等の誤検知を避ける）
REMOTE=$(git config --get remote.origin.url 2>/dev/null || true)
[[ "$REMOTE" =~ /dotfiles(\.git)?$ ]] || exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
DIFF_RANGE=$(session_diff_args "$SESSION_ID")

if [[ -n "$DIFF_RANGE" ]]; then
  # shellcheck disable=SC2086
  CHANGED=$(git diff --name-only $DIFF_RANGE 2>/dev/null)
else
  CHANGED=$(git diff --name-only HEAD~1 HEAD 2>/dev/null)
fi

[[ -n "$CHANGED" ]] || exit 0

# ドキュメント連動が必要なパターン
# 注: TRIGGER_RE は dot_claude/CLAUDE.md にもマッチするが、CLAUDE.md だけのコミットは
# 後段の DOC_RE チェックで早期 return するので警告は出ない。
TRIGGER_RE='^(dot_|private_|bootstrap\.sh)'
DOC_RE='^(README\.md|dot_claude/CLAUDE\.md)$'

TRIGGERED=$(echo "$CHANGED" | grep -E "$TRIGGER_RE" || true)
[[ -n "$TRIGGERED" ]] || exit 0

if echo "$CHANGED" | grep -qE "$DOC_RE"; then
  exit 0
fi

cat >&2 <<EOF
⚠️  ドキュメント整合性チェック
    dotfiles 管理対象が変更されましたが README.md / dot_claude/CLAUDE.md は更新されていません。

変更されたファイル:
$(echo "$TRIGGERED" | sed 's/^/  - /')

ドキュメント更新が不要な軽微変更なら無視してOK。
詳細は dot_claude/CLAUDE.md の「ドキュメント整合性ルール」を参照。
EOF

exit 0
