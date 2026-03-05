#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-${VITA_PIPELINE_IMAGE:-zzamboni/vita-pipeline:latest}}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURES_DIR="$ROOT_DIR/tests/container/fixtures"
TMP_DIR="$(mktemp -d)"
CACHE_DIR="$TMP_DIR/cache"
WORK_DIR="$TMP_DIR/work"

cleanup() {
    echo rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || {
    echo "error: expected file not found: $path" >&2
    exit 1
  }
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  rg -q "$pattern" "$path" || {
    echo "error: expected pattern '$pattern' not found in $path" >&2
    exit 1
  }
}

require_cmd docker
require_cmd rg
require_cmd bash

mkdir -p "$CACHE_DIR" "$WORK_DIR/fixtures"
cp "$FIXTURES_DIR/resume.json" "$WORK_DIR/fixtures/resume.json"
cp "$FIXTURES_DIR/publications.bib" "$WORK_DIR/fixtures/publications.bib"

run_wrapper() {
  (
    cd "$WORK_DIR"
    "$ROOT_DIR/build-resume.sh" --no-it "$@"
  )
}

echo "==> Test 1: task listing"
run_wrapper tasks >"$TMP_DIR/tasks.out"
assert_contains "$TMP_DIR/tasks.out" "^build\\b"
assert_contains "$TMP_DIR/tasks.out" "^fetch-logos\\b"
assert_contains "$TMP_DIR/tasks.out" "^update-certs\\b"

echo "==> Test 2: pipeline build with publications"
run_wrapper build fixtures/resume.json fixtures/publications.bib --out build/out >/dev/null

assert_file "$WORK_DIR/build/out/vita/index.html"
assert_file "$WORK_DIR/build/out/vita/resume.typ"
assert_file "$WORK_DIR/build/out/vita/resume.pdf"
assert_file "$WORK_DIR/build/out/vita/publications/index.html"
assert_file "$WORK_DIR/build/out/vita/publications/resume-pubs.pdf"
assert_file "$WORK_DIR/build/out/vita/publications/resume-pubs.bib"
assert_contains "$WORK_DIR/build/out/vita/index.html" "Example Person"
assert_contains "$WORK_DIR/build/out/vita/publications/index.html" "Example Person"

echo "==> Test 3: logo fetch dry-run wiring"
run_wrapper fetch-logos fixtures/resume.json --dry-run --token dummy >/dev/null

echo "All container tests passed."
