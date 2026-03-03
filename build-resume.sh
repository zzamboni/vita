#!/usr/bin/env bash
set -euo pipefail

IMAGE="${VITA_PIPELINE_IMAGE:-zzamboni/vita-pipeline:latest}"
PORT="${VITA_SERVE_PORT:-8080}"
CACHE_DIR="${VITA_PIPELINE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vita-pipeline}"

mkdir -p "$CACHE_DIR"

PORT_ARGS=()
for a in "$@"; do
  if [[ "$a" == "--serve" ]]; then
    PORT_ARGS=(-p "${PORT}:${PORT}")
    break
  fi
done

exec docker run --rm -it \
  -v "$PWD":/work \
  "${PORT_ARGS[@]}" \
  "$IMAGE" \
  build "$@"
