#!/bin/bash
# difit を cmux 内蔵ブラウザ（または WSL フォールバック）で開く
# 使い方: difit-open.sh [difit の引数...]

export PATH="$HOME/.local/share/mise/shims:/usr/local/bin:$PATH"

# cmux のバイナリを探す（macOS では Applications 配下にある場合がある）
_find_cmux() {
  if command -v cmux &>/dev/null; then
    echo "cmux"
  elif [[ -x "/Applications/cmux.app/Contents/Resources/bin/cmux" ]]; then
    echo "/Applications/cmux.app/Contents/Resources/bin/cmux"
  fi
}

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
  CMUX_BIN=$(_find_cmux)
  if [[ -n "$CMUX_BIN" ]] && "$CMUX_BIN" browser open "$URL" 2>/dev/null; then
    :
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    explorer.exe "$URL" 2>/dev/null || true
  fi
fi
