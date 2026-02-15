#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/run_pipeline.sh --json <file> [--bib <file> ...] --out <dir>

Required:
  --json <file>   JSON Resume input
  --bib <file>    BibTeX input (optional, repeatable)
  --out <dir>     Output base directory (will create <dir>/vita)

Example:
  scripts/run_pipeline.sh --json zamboni-vita.json --bib pubs-src/zamboni-pubs.bib --bib pubs-src/zamboni-patents.bib --out /tmp/vita-out
USAGE
}

json_file=""
output_dir=""
bib_files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      json_file="$2"
      shift 2
      ;;
    --bib)
      bib_files+=("$2")
      shift 2
      ;;
    --out)
      output_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$json_file" || -z "$output_dir" ]]; then
  usage
  exit 1
fi

if [[ ! -f "$json_file" ]]; then
  echo "JSON file not found: $json_file" >&2
  exit 1
fi

for bib in "${bib_files[@]}"; do
  if [[ ! -f "$bib" ]]; then
    echo "BibTeX file not found: $bib" >&2
    exit 1
  fi
done

out_vita="$output_dir/vita"
out_pubs="$out_vita/publications"
mkdir -p "$out_vita"

# Sync profile assets for Typst CV
mkdir -p "$out_vita/assets/profile"
cp -a assets/profile/* "$out_vita/assets/profile/"

# Render CV HTML
scripts/render_cv.sh "" "$json_file" "$out_vita/index.html"

# Render + compile CV PDF via Typst
python scripts/render_typst_cv.py "$json_file" "$out_vita/zamboni-vita.typ"
typst compile "$out_vita/zamboni-vita.typ" "$out_vita/zamboni-vita.pdf"

if [[ ${#bib_files[@]} -gt 0 ]]; then
  mkdir -p "$out_pubs"

  # Prepare temp bib dir for publications
  pubs_tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$pubs_tmp_dir"' EXIT

  for bib in "${bib_files[@]}"; do
    cp "$bib" "$pubs_tmp_dir/"
  done

  # Publications HTML + aggregated BibTeX
  PUBS_BIB_DIR="$pubs_tmp_dir" \
  PUBS_HTML="$out_pubs/index.html" \
  PUBS_OUT_DIR="$out_pubs" \
  PUBS_LINKS='[]' \
  python scripts/build_publications.py

  # Build publications PDF via LaTeX using aggregated BibTeX.
  agg_bib="$out_pubs/zamboni-pubs.bib"
  if [[ ! -f "$agg_bib" ]]; then
    echo "Aggregated bib not found: $agg_bib" >&2
    exit 1
  fi

  pubs_tex_src_dir="pubs-src"
  pubs_tex_src="${pubs_tex_src_dir}/zamboni-pubs.tex"

  if [[ ! -f "$pubs_tex_src" ]]; then
    echo "Publications tex template not found: $pubs_tex_src" >&2
    exit 1
  fi

  pubs_work_dir="$pubs_tmp_dir/tex"
  mkdir -p "$pubs_work_dir"
  cp -a "$pubs_tex_src_dir"/. "$pubs_work_dir"

  # Strip existing addbibresource lines, then add our aggregated bib.
  awk 'BEGIN { first = 1 }
    !/^\\addbibresource/ { print }
    /^\\addbibresource/ && first { first = 0; printf "\\addbibresource{zamboni-pubs.bib}\n" }
  ' "$pubs_tex_src" > "$pubs_work_dir/zamboni-pubs.tex"

  cp "$agg_bib" "$pubs_work_dir/zamboni-pubs.bib"

  (
    cd "$pubs_work_dir"
    tectonic -Z search-path=$(dirname $(kpsewhich biblatex.sty)) zamboni-pubs.tex
  )

  cp "$pubs_work_dir/zamboni-pubs.pdf" "$out_pubs/zamboni-pubs.pdf"
else
  rm -rf "$out_pubs"
fi

echo "Done. Output in: $out_vita"
