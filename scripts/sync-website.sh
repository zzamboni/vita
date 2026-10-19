#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: scripts/sync-website.sh [--website-dir PATH] [--build-script PATH] [--skip-build] [--dry-run]

Build canonical vita inputs with resume-toolkit --no-html and copy the website
JSON, CV/publications PDFs, and aggregated BibTeX to zzamboni.org.
No commits, pushes, or pull requests are made by this script.

Options:
  --website-dir PATH  Website checkout (default: ../zzamboni.org)
  --build-script PATH  resume-toolkit wrapper (default: build-resume.sh in PATH)
  --skip-build         Reuse existing build/zamboni-vita/vita outputs
  --dry-run            Show differences without modifying website files
HELP
}

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
website_dir="${VITA_WEBSITE_DIR:-$repo_dir/../zzamboni.org}"
build_script="${VITA_BUILD_SCRIPT:-build-resume.sh}"
skip_build=0
dry_run=0
while (($#)); do
  case "$1" in
    --website-dir|--build-script)
      if (($# < 2)); then echo "Missing value for $1" >&2; exit 2; fi
      case "$1" in
        --website-dir) website_dir="$2" ;;
        --build-script) build_script="$2" ;;
      esac
      shift 2 ;;
    --skip-build) skip_build=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

website_dir="$(cd "$website_dir" && pwd)" || { echo "Website checkout not found" >&2; exit 1; }
[[ -f "$website_dir/go.mod" && -d "$website_dir/data/jsonresume" ]] || {
  echo "Not a zzamboni.org checkout: $website_dir" >&2; exit 1
}
[[ -f "$repo_dir/zamboni-vita-full.json" ]] || { echo "Missing canonical resume JSON" >&2; exit 1; }

if (( ! skip_build )); then
  if [[ "$build_script" == */* ]]; then
    build_script="$(cd "$(dirname "$build_script")" && pwd)/$(basename "$build_script")"
  fi
  command -v "$build_script" >/dev/null || { echo "resume-toolkit wrapper not found: $build_script" >&2; exit 1; }
  # The container mounts the vita checkout at /work; use the website's CV stem.
  temp_input="$repo_dir/zamboni-vita.json"
  if [[ -e "$temp_input" ]]; then
    echo "Refusing to overwrite $temp_input" >&2; exit 1
  fi
  trap 'rm -f "$temp_input"' EXIT
  cp "$repo_dir/zamboni-vita-full.json" "$temp_input"
  (
    cd "$repo_dir"
    "$build_script" zamboni-vita.json --no-html --out build/zamboni-vita
  )
fi

out="$repo_dir/build/zamboni-vita/vita"
# Explicit allowlist: never rsync --delete a website directory.
sources=(
  "$repo_dir/zamboni-vita-full.json"
  "$out/publications/zamboni-vita-pubs.json"
  "$out/zamboni-vita.pdf"
  "$out/publications/zamboni-vita-pubs.pdf"
  "$out/publications/zamboni-vita-pubs.bib"
)
dests=(
  "$website_dir/data/jsonresume/resume.json"
  "$website_dir/data/jsonresume/publications.json"
  "$website_dir/static/vita/zamboni-vita.pdf"
  "$website_dir/static/vita/publications/zamboni-vita-pubs.pdf"
  "$website_dir/static/vita/publications/zamboni-vita-pubs.bib"
)

for i in "${!sources[@]}"; do
  [[ -s "${sources[i]}" ]] || { echo "Missing or empty output: ${sources[i]}" >&2; exit 1; }
done

# Validate both JSON files before any destination writes.
python3 -m json.tool "${sources[0]}" >/dev/null
python3 -m json.tool "${sources[1]}" >/dev/null

changed=0
for i in "${!sources[@]}"; do
  src="${sources[i]}"
  dest="${dests[i]}"
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    echo "Unchanged: ${dest#"$website_dir"/}"
    continue
  fi
  echo "Update: ${dest#"$website_dir"/}"
  changed=1
  if (( ! dry_run )); then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  fi
done
if (( ! changed )); then echo "Website files are already in sync."; fi
