#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
pane="$(context_field focused_pane_id)"
[ -n "$pane" ] || pane="${HERDR_PANE_ID:-}"
[ -n "$pane" ] || { echo "remote-open-url: no focused pane in context" >&2; exit 1; }
exec "$herdr" plugin pane open --plugin "${HERDR_PLUGIN_ID:-remote-open-url}" --entrypoint picker --env "REMOTE_OPEN_URL_PANE=$pane"
