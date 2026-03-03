#!/usr/bin/env bash
set -euo pipefail

export VITA_TOOLKIT_ROOT="/opt/vita-toolkit"
export VITA_WORKDIR="${VITA_WORKDIR:-/work}"
export VITA_SERVE_PORT="${VITA_SERVE_PORT:-8080}"
export MISE_IDIOMATIC_VERSION_FILE="${MISE_IDIOMATIC_VERSION_FILE:-false}"

mise trust "$VITA_TOOLKIT_ROOT/mise.toml" >/dev/null 2>&1 || true

run_pipeline_via_mise() {
  local watch=0
  local serve=0
  local resume=""
  local out=""
  local pubs_url=""
  local -a bibs=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --watch) watch=1; shift ;;
      --serve) serve=1; watch=1; shift ;;
      --out) out="$2"; shift 2 ;;
      --pubs-url) pubs_url="$2"; shift 2 ;;
      -h|--help)
        cat <<'USAGE'
Usage: vita-pipeline build <resume.json> [bibfiles...] [--out <dir>] [--pubs-url <url>] [--watch] [--serve]
USAGE
        return 0
        ;;
      --*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        if [[ -z "$resume" ]]; then
          resume="$1"
        else
          bibs+=("$1")
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$resume" ]]; then
    echo "Missing resume JSON file" >&2
    return 1
  fi

  local -a pipeline_args=("$resume")
  pipeline_args+=("${bibs[@]}")
  if [[ -n "$out" ]]; then
    pipeline_args+=(--out "$out")
  fi
  if [[ -n "$pubs_url" ]]; then
    pipeline_args+=(--pubs-url "$pubs_url")
  fi

  local out_base="$out"
  if [[ -z "$out_base" ]]; then
    out_base="build/$(basename "${resume%.json}")"
  fi

  cd "$VITA_WORKDIR"

  if [[ "$serve" == "1" ]]; then
    mkdir -p "$out_base"
    echo "→ Serving $out_base at http://localhost:$VITA_SERVE_PORT"
    python3 -m http.server "$VITA_SERVE_PORT" --bind 0.0.0.0 --directory "$out_base" >/dev/null 2>&1 &
    local server_pid=$!
    trap 'kill "$server_pid" >/dev/null 2>&1 || true' EXIT INT TERM
  fi

  if [[ "$watch" == "1" ]]; then
    export DEV_RELOAD=1
    (
      cd "$VITA_TOOLKIT_ROOT"
#      mise run pipeline "${pipeline_args[@]}"
      exec mise x -- watchexec --restart \
          --watch "$VITA_WORKDIR/$resume" \
          $(for bib in "${bibs[@]}"; do printf -- '--watch %q ' "$VITA_WORKDIR/$bib"; done) \
          -- bash -lc 'cd "'"$VITA_TOOLKIT_ROOT"'" && DEV_RELOAD=1 mise run --force pipeline '"${pipeline_args[@]}" 
    )
  else
    (
      cd "$VITA_TOOLKIT_ROOT"
      exec mise run pipeline "${pipeline_args[@]}"
    )
  fi
}

if [[ $# -eq 0 ]]; then
  cd "$VITA_TOOLKIT_ROOT"
  exec mise tasks ls
fi

case "$1" in
  build|pipeline)
    shift
    run_pipeline_via_mise "$@"
    ;;
  shell|bash)
    exec mise x -- bash "${@:2}"
    ;;
  run|tasks|trust|install|exec|x|watch|which|where|settings|doctor|version|help)
    cd "$VITA_TOOLKIT_ROOT"
    exec mise "$@"
    ;;
  *)
    cd "$VITA_TOOLKIT_ROOT"
    exec mise run "$@"
    ;;
esac
