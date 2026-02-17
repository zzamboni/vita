#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${VITA_PIPELINE_IMAGE:-zzamboni/vita-pipeline:latest}"

if [[ "${1:-}" == "--image" ]]; then
  IMAGE_NAME="$2"
  shift 2
fi

exec docker run --rm \
  -v "$PWD":/work \
  -w /work \
  "$IMAGE_NAME" \
  "$@"
