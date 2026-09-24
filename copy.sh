#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")" && . ./lib.sh
url="${REMOTE_OPEN_URL_TARGET:-}"
[ -n "$url" ] || exit 1
copy_url "$url"
printf 'Copied to clipboard:\n  %s\n' "$url"
"$herdr" notification show "Copied to clipboard" --body "$url" >/dev/null 2>&1
sleep 1.2
