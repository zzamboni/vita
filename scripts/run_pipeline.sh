#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
toolkit_root="${VITA_TOOLKIT_ROOT:-$(cd "$script_dir/.." && pwd)}"
workdir="${VITA_WORKDIR:-$PWD}"

usage() {
  cat <<'USAGE'
Usage: scripts/run_pipeline.sh --json <file> [--bib <file> ...] [--pubs-url <url>] --out <dir>

Required:
  --json <file>   JSON Resume input (relative to working dir or absolute path)
  --out <dir>     Output base directory (relative to working dir or absolute path)

Optional:
  --bib <file>    BibTeX input (repeatable)
  --pubs-url <url>  Online publications URL used in generated publications PDF footer

Example:
  scripts/run_pipeline.sh --json resume.json --bib publications.bib --pubs-url https://example.org/vita/publications --out build/out
USAGE
}

resolve_path() {
  local p="$1"
  if [[ "$p" = /* ]]; then
    printf '%s\n' "$p"
  else
    printf '%s\n' "$workdir/$p"
  fi
}

json_file=""
output_dir=""
pubs_url=""
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
    --pubs-url)
      pubs_url="$2"
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

json_file="$(resolve_path "$json_file")"
out_base="$(resolve_path "$output_dir")"
json_name="$(basename "$json_file")"
json_stem="${json_name%.*}"

cv_typ_name="${json_stem}.typ"
cv_pdf_name="${json_stem}.pdf"
pubs_base_name="${json_stem}-pubs"
pubs_bib_name="${pubs_base_name}.bib"
pubs_tex_name="${pubs_base_name}.tex"
pubs_pdf_name="${pubs_base_name}.pdf"

resume_name="$(
  python - "$json_file" <<'PY'
import json
import sys
from pathlib import Path

def esc(s: str) -> str:
    rep = {
        "\\": r"\textbackslash{}",
        "{": r"\{",
        "}": r"\}",
        "#": r"\#",
        "$": r"\$",
        "%": r"\%",
        "&": r"\&",
        "_": r"\_",
        "^": r"\^{}",
        "~": r"\~{}",
    }
    return "".join(rep.get(ch, ch) for ch in s)

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
name = data.get("basics", {}).get("name", "Publications")
print(esc(str(name)))
PY
)"

pubs_url_display="${pubs_url#https://}"
pubs_url_display="${pubs_url_display#http://}"

if [[ ! -f "$json_file" ]]; then
  echo "JSON file not found: $json_file" >&2
  exit 1
fi

for i in "${!bib_files[@]}"; do
  bib_files[$i]="$(resolve_path "${bib_files[$i]}")"
  if [[ ! -f "${bib_files[$i]}" ]]; then
    echo "BibTeX file not found: ${bib_files[$i]}" >&2
    exit 1
  fi
done

out_vita="$out_base/vita"
out_pubs="$out_vita/publications"
mkdir -p "$out_vita"

# Sync profile assets for Typst CV
mkdir -p "$out_vita/assets/profile"
if compgen -G "$toolkit_root/assets/profile/*" >/dev/null; then
  cp -a "$toolkit_root/assets/profile"/* "$out_vita/assets/profile/"
fi

# Render CV HTML
"$toolkit_root/scripts/render_cv.sh" "" "$json_file" "$out_vita/index.html"

# Render + compile CV PDF via Typst
python "$toolkit_root/scripts/render_typst_cv.py" "$json_file" "$out_vita/$cv_typ_name"
typst compile "$out_vita/$cv_typ_name" "$out_vita/$cv_pdf_name"

if [[ ${#bib_files[@]} -gt 0 ]]; then
  mkdir -p "$out_pubs"

  pubs_tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$pubs_tmp_dir"' EXIT

  for bib in "${bib_files[@]}"; do
    cp "$bib" "$pubs_tmp_dir/"
  done

  pubs_links_json="$(printf '[{\"name\":\"PDF\",\"url\":\"/vita/publications/%s\",\"icon\":\"file-pdf\"},{\"name\":\"BibTeX\",\"url\":\"/vita/publications/%s\",\"icon\":\"book\"}]' "$pubs_pdf_name" "$pubs_bib_name")"

  # Publications HTML + aggregated BibTeX
  (
    cd "$toolkit_root"
    PUBS_BIB_DIR="$pubs_tmp_dir" \
    PUBS_HTML="$out_pubs/index.html" \
    PUBS_OUT_DIR="$out_pubs" \
    PUBS_BIB_FILENAME="$pubs_bib_name" \
    PUBS_LINKS="$pubs_links_json" \
    python scripts/build_publications.py
  )

  agg_bib="$out_pubs/$pubs_bib_name"
  if [[ ! -f "$agg_bib" ]]; then
    echo "Aggregated bib not found: $agg_bib" >&2
    exit 1
  fi

  pubs_assets_dir="$toolkit_root/pubs-assets"
  if [[ ! -f "$pubs_assets_dir/awesome-cv.cls" ]]; then
    echo "Publications class file not found: $pubs_assets_dir/awesome-cv.cls" >&2
    exit 1
  fi

  pubs_work_dir="$pubs_tmp_dir/tex"
  mkdir -p "$pubs_work_dir"
  cp -a "$pubs_assets_dir"/. "$pubs_work_dir"

  if [[ -n "$pubs_url" ]]; then
    footer_center="${resume_name}~~~·~~~Publications\\\\\\textup{\\tiny Online at \\href{${pubs_url}}{\\nolinkurl{${pubs_url_display}}}}"
  else
    footer_center="${resume_name}~~~·~~~Publications"
  fi

  cat > "$pubs_work_dir/$pubs_tex_name" <<LATEX
\documentclass[12pt,a4paper]{awesome-cv}
\usepackage[defernumbers=true,style=numeric,sorting=ydnt,backend=biber]{biblatex}
\addbibresource{$pubs_bib_name}
\defbibheading{cvbibsection}[\bibname]{\cvsubsection{#1}}
\renewcommand*{\bodyfontlight}{\sourcesanspro}
\renewcommand*{\bibfont}{\paragraphstyle}
\AtBeginBibliography{\raggedright\emergencystretch=1em}
\renewcommand*{\entrylocationstyle}[1]{{\fontsize{10pt}{1em}\bodyfontlight\slshape\color{awesome} #1}}
\renewcommand*{\subsectionstyle}{\entrytitlestyle}
\renewcommand*{\headerquotestyle}[1]{{\fontsize{8pt}{1em}\bodyfont #1}}
\fontdir[fonts/]
\colorlet{awesome}{awesome-concrete}
\setbool{acvSectionColorHighlight}{false}
\colorizelinks[awesome-skyblue]
\hypersetup{
 pdftitle={Publications},
 pdflang={English}}
\begin{document}
\makecvfooter{\today}{$footer_center}{\thepage}
\cvsubsection{$resume_name}
\cvsection{Publications}
\label{publications}
\nocite{*}
\printbibliography[keyword=book,          heading=cvbibsection, title=Books]
\printbibliography[keyword=editorial,     heading=cvbibsection, title=Editorial Activities]
\printbibliography[keyword=thesis,        heading=cvbibsection, title=Theses]
\printbibliography[keyword=refereed,      heading=cvbibsection, title=Refereed Papers]
\printbibliography[keyword=techreport,    heading=cvbibsection, title=Tech Reports]
\printbibliography[keyword=presentations, heading=cvbibsection, title=Presentations at Conferences and Workshops]
\printbibliography[keyword=invited,       heading=cvbibsection, title=Invited Talks and Articles]
\printbibliography[keyword=patent,        heading=cvbibsection, title=Patents]
\printbibliography[keyword=other,         heading=cvbibsection, title=Other Publications]
\end{document}
LATEX

  cp "$agg_bib" "$pubs_work_dir/$pubs_bib_name"

  (
    cd "$pubs_work_dir"
    tectonic "$pubs_tex_name"
  )

  cp "$pubs_work_dir/$pubs_pdf_name" "$out_pubs/$pubs_pdf_name"
else
  rm -rf "$out_pubs"
fi

echo "Done. Output in: $out_vita"
