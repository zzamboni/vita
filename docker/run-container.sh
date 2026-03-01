#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${VITA_PIPELINE_IMAGE:-zzamboni/vita-pipeline:latest}"
CACHE_DIR="${VITA_PIPELINE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vita-pipeline}"
PORT_ARG=""
if [[ -n "${VITA_PIPELINE_PORT_MAP:-}" ]]; then
    PORT_ARG="-p ${VITA_PIPELINE_PORT_MAP}"
fi

if [[ "${1:-}" == "--image" ]]; then
  IMAGE_NAME="$2"
  shift 2
fi

ITARG=""
if [[ "${1:-}" == "-it" ]]; then
    ITARG="-it"
    shift 1
fi

if [[ "${1:-}" == "bash" || "${1:-}" == "shell" ]]; then
    ITARG="-it"
fi

container_args=("$@")

mkdir -p "$CACHE_DIR"

exec docker run $ITARG --rm \
    --user "$(id -u):$(id -g)" \
    $PORT_ARG \
    -e HOME=/tmp \
    -e XDG_CACHE_HOME=/opt/vita-cache \
    -e TECTONIC_CACHE_DIR=/opt/vita-cache/tectonic \
    -e MISE_DATA_DIR=/opt/vita-cache/mise \
    -e MISE_STATE_DIR=/opt/vita-cache/mise/state \
    -e MISE_CACHE_DIR=/opt/vita-cache/mise/cache \
    -e MISE_IDIOMATIC_VERSION_FILE=false \
    -e VITA_WORKDIR=/work \
    -v "$CACHE_DIR":/opt/vita-cache \
    -v "$PWD":/work \
    -w /work \
    "$IMAGE_NAME" \
    "${container_args[@]}"
