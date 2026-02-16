#!/usr/bin/env bash
set -euo pipefail

export VITA_TOOLKIT_ROOT="/opt/vita-toolkit"
export VITA_WORKDIR="${VITA_WORKDIR:-/work}"

exec /opt/vita-toolkit/scripts/run_pipeline.sh "$@"
