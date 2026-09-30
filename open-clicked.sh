#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
load_config
url="${HERDR_PLUGIN_CLICKED_URL:-$(context_field clicked_url)}"
[ -n "$url" ] || { echo "remote-open-url: no clicked URL in context" >&2; exit 1; }
pane="$(context_field focused_pane_id)"
[ -n "$pane" ] || pane="${HERDR_PANE_ID:-}"
[ -z "$pane" ] || url="$(full_url "$pane" "$url")"
if can_open; then
  open_url "$url" && "$herdr" notification show "Opened" --body "$url" >/dev/null 2>&1
else
  exec "$herdr" plugin pane open --plugin "${HERDR_PLUGIN_ID:-remote-open-url}" --entrypoint copy --env "REMOTE_OPEN_URL_TARGET=$url"
fi
