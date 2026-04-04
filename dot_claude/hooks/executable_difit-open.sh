#!/bin/bash
# difit を cmux 内蔵ブラウザ（または WSL フォールバック）で開く
# 使い方: difit-open.sh [difit の引数...]

export PATH="$HOME/.local/share/mise/shims:/usr/local/bin:$PATH"

TMPFILE=$(mktemp)
nohup difit "$@" --no-open > "$TMPFILE" 2>&1 &
disown

URL=""
for _ in $(seq 1 20); do
  URL=$(grep -o 'http://localhost:[0-9]*' "$TMPFILE" 2>/dev/null | head -1)
  [[ -n "$URL" ]] && break
  sleep 0.2
done
rm -f "$TMPFILE"

if [[ -n "$URL" ]]; then
  if cmux browser open "$URL" 2>/dev/null; then
    :
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    explorer.exe "$URL" 2>/dev/null || true
  fi
fi
