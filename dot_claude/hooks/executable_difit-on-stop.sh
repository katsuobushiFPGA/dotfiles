#!/bin/bash
# git 管理下で変更がある場合に difit で差分を表示する

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

if ! git diff --quiet 2>/dev/null || ! git diff --staged --quiet 2>/dev/null; then
  nohup difit HEAD > /dev/null 2>&1 &
  disown
fi
