#!/bin/bash
# Claude Code フック共通ライブラリ（source して使う）

CACHE_DIR="${HOME}/.cache/claude-hooks"

# SESSION_ID からセッション差分の difit 引数を返す
# HEAD が変化していない場合は空文字を返す
session_diff_args() {
  local session_id="$1"
  local initial_head current_head
  initial_head=$(cat "${CACHE_DIR}/initial-head-${session_id}" 2>/dev/null)
  current_head=$(git rev-parse HEAD 2>/dev/null)
  [[ -n "$initial_head" && "$initial_head" != "$current_head" ]] && echo "${initial_head}..${current_head}"
}
