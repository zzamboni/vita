#!/usr/bin/env bash
set -euo pipefail

export VITA_TOOLKIT_ROOT="/opt/vita-toolkit"
export VITA_WORKDIR="${VITA_WORKDIR:-/work}"

mise trust "$VITA_WORKDIR" >/dev/null 2>&1 || true

if [[ $# -eq 0 ]]; then
  exec mise tasks ls
fi

case "$1" in
  shell|bash)
    exec mise x -- bash "${@:2}"
    ;;
  run|tasks|trust|install|exec|x|watch|which|where|settings|doctor|version|help)
    exec mise "$@"
    ;;
  *)
    exec mise run "$@"
    ;;
esac
