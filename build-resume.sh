#!/usr/bin/env bash
set -euo pipefail

IMAGE="${VITA_PIPELINE_IMAGE:-zzamboni/vita-pipeline:latest}"
PORT="${VITA_SERVE_PORT:-8080}"
CACHE_DIR="${VITA_PIPELINE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vita-pipeline}"

mkdir -p "$CACHE_DIR"

PORT_ARGS=()
ENV_ARGS=()
CMD=build

if [[ "${1:-}" == "--bash" ]]; then
  CMD=bash
  shift
elif [[ "${1:-}" == "--fetch-logos" ]]; then
  CMD=logos
  if [[ -n "${LOGODEV_TOKEN:-}" ]]; then
    ENV_ARGS=(-e "LOGODEV_TOKEN=$LOGODEV_TOKEN")
  fi
  shift
elif [[ "${1:-}" == "--update-certs" ]]; then
  CMD=certs-update
  shift
fi

for a in "$@"; do
  if [[ "$a" == "--serve" ]]; then
    PORT_ARGS=(-p "${PORT}:${PORT}")
    break
  fi
done

exec docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -v "$PWD":/work \
  -v "$CACHE_DIR":/opt/vita-cache \
  -w /work \
  -e VITA_WORKDIR=/work \
  -e VITA_SERVE_PORT="$PORT" \
  -e MISE_IDIOMATIC_VERSION_FILE=false \
  "${ENV_ARGS[@]}" \
  "${PORT_ARGS[@]}" \
  "$IMAGE" \
  $CMD "$@"
