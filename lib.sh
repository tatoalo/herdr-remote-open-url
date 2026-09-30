#!/usr/bin/env bash

herdr="${HERDR_BIN_PATH:-herdr}"

load_config() {
  local f="${HERDR_PLUGIN_CONFIG_DIR:-}/.env"
  if [ -f "$f" ]; then set -a; . "$f"; set +a; fi
}

context_field() {
  printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" | python3 -c '
import json, sys
try: print(json.load(sys.stdin).get(sys.argv[1]) or "")
except Exception: print("")' "$1" 2>/dev/null
}

can_open() {
  case "${REMOTE_OPEN_URL_MODE:-auto}" in open) return 0 ;; copy) return 1 ;; esac
  case "$(uname -s)" in
    Darwin) command -v open >/dev/null 2>&1 ;;
    *) [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && command -v xdg-open >/dev/null 2>&1 ;;
  esac
}

open_url() {
  case "$(uname -s)" in
    Darwin) open "$1" ;;
    *) xdg-open "$1" >/dev/null 2>&1 & ;;
  esac
}

copy_url() {
  printf '\e]52;c;%s\a' "$(printf '%s' "$1" | base64 | tr -d '\n')"
}

extract_urls() {
  local esc
  esc="$(printf '\033')"
  sed -E "s/${esc}\[[0-9;]*[A-Za-z]//g" \
    | grep -oE 'https?://[A-Za-z0-9._~:/?#@!$&*+,;=%()-]+' \
    | sed -E 's/[).,;:]+$//' \
    | awk '!seen[$0]++'
}

pane_rows() {
  "$herdr" pane get "$1" 2>/dev/null | python3 -c '
import json, sys
try: print(json.load(sys.stdin)["result"]["pane"]["scroll"]["viewport_rows"])
except Exception: print("")' 2>/dev/null
}

pane_urls() {
  local pane="$1" out="" rows
  rows="$(pane_rows "$pane")"
  [ -z "$rows" ] || out="$("$herdr" pane read "$pane" --source recent-unwrapped --lines "$rows" --format text 2>/dev/null | extract_urls)"
  [ -n "$out" ] || out="$("$herdr" pane read "$pane" --source visible --format text 2>/dev/null | extract_urls)"
  [ -n "$out" ] || [ -z "${REMOTE_OPEN_URL_LINES:-}" ] \
    || out="$("$herdr" pane read "$pane" --source recent-unwrapped --lines "$REMOTE_OPEN_URL_LINES" --format text 2>/dev/null | extract_urls)"
  printf '%s' "$out"
}

full_url() {
  pane_urls "$1" | U="$2" awk 'index($0, ENVIRON["U"]) == 1 && length($0) > length(best) { best = $0 } END { print (best != "" ? best : ENVIRON["U"]) }'
}
