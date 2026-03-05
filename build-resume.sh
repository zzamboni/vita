#!/usr/bin/env bash
set -euo pipefail

IMAGE="${VITA_PIPELINE_IMAGE:-zzamboni/vita-pipeline:latest}"
PORT="${VITA_SERVE_PORT:-8080}"
CACHE_DIR="${VITA_PIPELINE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vita-pipeline}"

mkdir -p "$CACHE_DIR"

PORT_ARGS=()
ENV_ARGS=()
CMD=build
ARGS=("$@")

usage() {
  cat <<'USAGE'
Usage:
  build-resume.sh [build] <resume.json> [bibfiles...] [--out <dir>] [--pubs-url <url>] [--watch] [--serve]
  build-resume.sh fetch-logos <resume.json> [--overwrite] [--dry-run]
  build-resume.sh update-certs <username> <resume.json> [--include-expired] [--include-non-cert-badges] [--sort <date_desc|date_asc|name>]
  build-resume.sh <subcommand> [args...] (use 'build-resume.sh tasks' to see list)

Examples:
  build-resume.sh zamboni-vita.json pubs-src/zamboni-pubs.bib --watch --serve
  build-resume.sh fetch-logos zamboni-vita.json --overwrite
  build-resume.sh update-certs zzamboni zamboni-vita.json
  build-resume.sh tasks
USAGE
}

# Harmonize with container entrypoint commands.
ENTRYPOINT_CMDS=(
  build pipeline shell bash
  run tasks trust install exec x watch which where settings doctor version help
  fetch-logos update-certs
)

is_entrypoint_cmd() {
  local candidate="$1"
  for c in "${ENTRYPOINT_CMDS[@]}"; do
    [[ "$candidate" == "$c" ]] && return 0
  done
  return 1
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  "")
    usage
    exit 1
    ;;
  *)
    if is_entrypoint_cmd "$1"; then
      CMD="$1"
      ARGS=("${@:2}")
    else
      # Default behavior remains build without explicit subcommand.
      CMD=build
      ARGS=("$@")
    fi
    ;;
esac

if [[ "$CMD" == "fetch-logos" && -n "${LOGODEV_TOKEN:-}" ]]; then
  ENV_ARGS+=(-e "LOGODEV_TOKEN=$LOGODEV_TOKEN")
fi

for a in "${ARGS[@]}"; do
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
  "$CMD" "${ARGS[@]}"
