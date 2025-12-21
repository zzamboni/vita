#!/usr/bin/env bash
set -euo pipefail

theme="${1:-}"
cv_json="$2"
cv_html="$3"

mkdir -p "$(dirname "$cv_html")"

echo "→ Rendering CV to $cv_html"
if [[ -n "$theme" ]]; then
  npx resumed render --theme "$theme" --output "$cv_html" "$cv_json"
else
  npx resumed render --output "$cv_html" "$cv_json"
fi

