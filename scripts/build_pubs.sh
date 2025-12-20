#!/usr/bin/env bash
set -euo pipefail

dev_reload="$1"     # 1 or 0
pubs_html="$2"
pubs_script="$3"

mkdir -p "$(dirname "$pubs_html")"

echo "→ Building publications to $pubs_html (DEV_RELOAD=$dev_reload)"
DEV_RELOAD="$dev_reload" PUBS_HTML="$pubs_html" python3 "$pubs_script"

