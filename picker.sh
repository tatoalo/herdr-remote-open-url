#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
load_config
export PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"

reverse() {
  if command -v tac >/dev/null 2>&1; then tac; else tail -r; fi
}

pane="${REMOTE_OPEN_URL_PANE:-}"
[ -n "$pane" ] || { echo "remote-open-url: REMOTE_OPEN_URL_PANE is not set"; sleep 1.5; exit 1; }
urls="$(pane_urls "$pane")"
if [ "${1:-}" = "--list" ]; then printf '%s\n' "$urls"; exit 0; fi
if [ -z "$urls" ]; then echo "No URLs in this pane."; sleep 1.2; exit 0; fi

list="$(printf '%s\n' "$urls" | reverse)"
if command -v fzf >/dev/null 2>&1; then
  url="$(printf '%s\n' "$list" | fzf --layout=reverse --info=inline --no-sort --exit-0 --select-1 \
        --prompt="$(can_open && echo 'open url > ' || echo 'copy url > ')")" || exit 0
else
  printf '%s\n' "$list" | nl -w2 -s'  '
  printf 'number > '; read -r n
  url="$(printf '%s\n' "$list" | sed -n "${n}p")"
fi
[ -n "$url" ] || exit 0

if can_open; then
  open_url "$url" && "$herdr" notification show "Opened" --body "$url" >/dev/null 2>&1
else
  copy_url "$url"
  "$herdr" notification show "Copied to clipboard" --body "$url" >/dev/null 2>&1 || { printf 'Copied: %s\n' "$url"; sleep 1; }
fi
