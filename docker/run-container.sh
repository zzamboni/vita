#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${VITA_PIPELINE_IMAGE:-zzamboni/vita-pipeline:latest}"

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

exec docker run $ITARG --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -e MISE_DATA_DIR=/work/.mise \
    -e MISE_STATE_DIR=/work/.mise/state \
    -e MISE_CACHE_DIR=/work/.mise/cache \
    -v "$PWD":/work \
    -w /work \
    "$IMAGE_NAME" \
    "${container_args[@]}"
