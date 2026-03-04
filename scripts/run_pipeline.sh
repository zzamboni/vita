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
  --bib <file>      BibTeX input (repeatable)
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

calc_hash() {
  {
    for entry in "$@"; do
      case "$entry" in
        STR:*)
          printf 'STR\n%s\n' "${entry#STR:}"
          ;;
        FILE:*)
          local f="${entry#FILE:}"
          if [[ -f "$f" ]]; then
            printf 'FILE\n%s\n' "$f"
            sha256sum "$f"
          else
            printf 'MISSING_FILE\n%s\n' "$f"
          fi
          ;;
        DIR:*)
          local d="${entry#DIR:}"
          if [[ -d "$d" ]]; then
            printf 'DIR\n%s\n' "$d"
            while IFS= read -r -d '' p; do
              printf 'PATH\n%s\n' "$p"
              sha256sum "$p"
            done < <(find "$d" -type f -print0 | sort -z)
          else
            printf 'MISSING_DIR\n%s\n' "$d"
          fi
          ;;
      esac
    done
  } | sha256sum | awk '{print $1}'
}

needs_rebuild() {
  local out_file="$1"
  local stamp_file="$2"
  local new_hash="$3"
  [[ ! -f "$out_file" || ! -f "$stamp_file" || "$(cat "$stamp_file" 2>/dev/null || true)" != "$new_hash" ]]
}

mark_built() {
  local stamp_file="$1"
  local new_hash="$2"
  printf '%s\n' "$new_hash" > "$stamp_file"
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

if [[ -z "$json_file" ]]; then
  usage
  exit 1
fi

if [[ -z "$output_dir" ]]; then
    output_dir="build/$(basename $json_file .json)"
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

out_vita="$out_base/vita"
out_pubs="$out_vita/publications"
mkdir -p "$out_vita"

state_dir="$out_base/.pipeline-state/$json_stem"
mkdir -p "$state_dir"

# Sync profile assets for Typst CV

mkdir -p "$out_vita/assets/profile"
if compgen -G "$toolkit_root/assets/profile/*" >/dev/null; then
  cp -a "$toolkit_root/assets/profile"/* "$out_vita/assets/profile/"
fi

cv_html="$out_vita/index.html"
cv_html_hash="$(calc_hash \
  "FILE:$json_file" \
  "FILE:$toolkit_root/scripts/render_cv.sh" \
  "STR:cv_html_target=$cv_html")"
if needs_rebuild "$cv_html" "$state_dir/cv-html.sha" "$cv_html_hash"; then
  echo "→ Building CV HTML"
  "$toolkit_root/scripts/render_cv.sh" "" "$json_file" "$cv_html"
  mark_built "$state_dir/cv-html.sha" "$cv_html_hash"
else
  echo "→ CV HTML up to date"
fi

# Optional dev autoreload snippet injection (enabled by DEV_RELOAD=1)
if [[ "${DEV_RELOAD:-0}" == "1" ]] && [[ -f "$cv_html" ]] && ! grep -q "__reload" "$cv_html"; then
  perl -0777 -pe 's~</body>~\n<script>\n(() => {\n  const self = new URL(location.href);\n  self.searchParams.set("__reload", Date.now().toString());\n  let lastModified = null;\n  async function check() {\n    try {\n      const res = await fetch(self.toString(), { cache: "no-store" });\n      const lm = res.headers.get("last-modified") || null;\n      if (lastModified === null) { lastModified = lm; return; }\n      if (lm && lastModified && lm !== lastModified) location.reload();\n    } catch (e) {}\n  }\n  setInterval(check, 800);\n})();\n</script>\n</body>~s' -i "$cv_html"
fi

# Render + compile CV PDF via Typst
cv_typ="$out_vita/$cv_typ_name"
cv_pdf="$out_vita/$cv_pdf_name"
cv_typ_hash="$(calc_hash \
  "FILE:$json_file" \
  "FILE:$toolkit_root/scripts/render_typst_cv.py" \
  "DIR:$toolkit_root/assets/profile" \
  "DIR:$toolkit_root/assets/logos" \
  "STR:cv_typ_target=$cv_typ")"
if needs_rebuild "$cv_typ" "$state_dir/cv-typ.sha" "$cv_typ_hash"; then
  echo "→ Building Typst source"
  python "$toolkit_root/scripts/render_typst_cv.py" "$json_file" "$cv_typ"
  mark_built "$state_dir/cv-typ.sha" "$cv_typ_hash"
else
  echo "→ Typst source up to date"
fi

cv_pdf_hash="$(calc_hash \
  "FILE:$cv_typ" \
  "DIR:$out_vita/assets/profile" \
  "DIR:$out_vita/assets/logos" \
  "STR:cv_pdf_target=$cv_pdf")"
if needs_rebuild "$cv_pdf" "$state_dir/cv-pdf.sha" "$cv_pdf_hash"; then
  echo "→ Building CV PDF"
  typst compile "$cv_typ" "$cv_pdf"
  mark_built "$state_dir/cv-pdf.sha" "$cv_pdf_hash"
else
  echo "→ CV PDF up to date"
fi

if [[ ${#bib_files[@]} -gt 0 ]]; then
  mkdir -p "$out_pubs"

  pubs_tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$pubs_tmp_dir"' EXIT

  sorted_bibs=("${bib_files[@]}")
  if [[ ${#sorted_bibs[@]} -gt 0 ]]; then
    IFS=$'\n' sorted_bibs=($(printf '%s\n' "${sorted_bibs[@]}" | sort))
    unset IFS
  fi

  for bib in "${sorted_bibs[@]}"; do
    cp "$bib" "$pubs_tmp_dir/"
  done

  pubs_links_json="$(printf '[{\"name\":\"PDF\",\"url\":\"/vita/publications/%s\",\"icon\":\"file-pdf\"},{\"name\":\"BibTeX\",\"url\":\"/vita/publications/%s\",\"icon\":\"tex\"}]' "$pubs_pdf_name" "$pubs_bib_name")"

  pubs_html="$out_pubs/index.html"
  agg_bib="$out_pubs/$pubs_bib_name"
  resume_name=$(jq -r '.basics.name // ""' $json_file)
  pubs_html_hash_args=(
    "FILE:$toolkit_root/scripts/build_publications.py"
    "FILE:$toolkit_root/templates/publications.html.j2"
    "STR:resume_name=$resume_name"
    "STR:pubs_links=$pubs_links_json"
    "STR:pubs_bib_name=$pubs_bib_name"
  )
  for bib in "${sorted_bibs[@]}"; do
    pubs_html_hash_args+=("FILE:$bib")
  done
  pubs_html_hash="$(calc_hash "${pubs_html_hash_args[@]}")"
  if needs_rebuild "$pubs_html" "$state_dir/pubs-html.sha" "$pubs_html_hash" || needs_rebuild "$agg_bib" "$state_dir/pubs-html.sha" "$pubs_html_hash"; then
    echo "→ Building publications HTML + BibTeX"
    (
      cd "$toolkit_root"
      PUBS_BIB_DIR="$pubs_tmp_dir" \
      PUBS_HTML="$pubs_html" \
      PUBS_OUT_DIR="$out_pubs" \
      PUBS_BIB_FILENAME="$pubs_bib_name" \
      PUBS_RESUME_JSON="$json_file" \
      PUBS_LINKS="$pubs_links_json" \
      python scripts/build_publications.py
      # Optional dev autoreload snippet injection (enabled by DEV_RELOAD=1)
      if [[ "${DEV_RELOAD:-0}" == "1" ]] && [[ -f "$pubs_html" ]] && ! grep -q "__reload" "$pubs_html"; then
        perl -0777 -pe 's~</body>~\n<script>\n(() => {\n  const self = new URL(location.href);\n  self.searchParams.set("__reload", Date.now().toString());\n  let lastModified = null;\n  async function check() {\n    try {\n      const res = await fetch(self.toString(), { cache: "no-store" });\n      const lm = res.headers.get("last-modified") || null;\n      if (lastModified === null) { lastModified = lm; return; }\n      if (lm && lastModified && lm !== lastModified) location.reload();\n    } catch (e) {}\n  }\n  setInterval(check, 800);\n})();\n</script>\n</body>~s' -i "$pubs_html"
      fi
    )
    mark_built "$state_dir/pubs-html.sha" "$pubs_html_hash"
  else
    echo "→ Publications HTML + BibTeX up to date"
  fi

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

  pubs_pdf="$out_pubs/$pubs_pdf_name"
  pubs_pdf_hash="$(calc_hash \
    "FILE:$toolkit_root/scripts/run_pipeline.sh" \
    "FILE:$agg_bib" \
    "DIR:$pubs_assets_dir" \
    "STR:resume_name=$resume_name" \
    "STR:pubs_tex_name=$pubs_tex_name" \
    "STR:pubs_pdf_name=$pubs_pdf_name" \
    "STR:resume_name=$resume_name" \
    "STR:pubs_url=$pubs_url")"
  if needs_rebuild "$pubs_pdf" "$state_dir/pubs-pdf.sha" "$pubs_pdf_hash"; then
    echo "→ Building publications PDF"
    (
      cd "$pubs_work_dir"
      tectonic "$pubs_tex_name"
    )
    cp "$pubs_work_dir/$pubs_pdf_name" "$pubs_pdf"
    mark_built "$state_dir/pubs-pdf.sha" "$pubs_pdf_hash"
  else
    echo "→ Publications PDF up to date"
  fi
else
  rm -rf "$out_pubs"
fi

echo "Done. Output in: $out_vita"
