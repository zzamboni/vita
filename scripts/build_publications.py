#!/usr/bin/env python3

from pathlib import Path
import bibtexparser
from jinja2 import Environment, FileSystemLoader
from datetime import datetime, UTC
import logging
from collections import defaultdict
import re
import html
import json
import os

#logging.getLogger("bibtexparser").setLevel(logging.ERROR)

BIB_DIR = Path("src")
OUT_FILE = Path(os.environ.get("PUBS_HTML", "dist/publications.html"))
TEMPLATE_DIR = Path("templates")

EXPORT_SELECTED = False
SELECTED_KEYWORD = "selected"
SELECTED_OUT_FILE = Path("site/selected-publications.json")

SECTION_ORDER = [
    "book",
    "refereed",
    "editorial",
    "techreport",
    "thesis",
    "presentations",
    "invited",
    "patent",
    "other",
]

SECTION_TITLES = {
    "book": "Books",
    "editorial": "Editorial Activities",
    "thesis": "Theses",
    "refereed": "Refereed Papers",
    "techreport": "Technical Reports",
    "presentations": "Presentations",
    "invited": "Invited Talks and Articles",
    "patent": "Patents",
    "other": "Other Publications",
}


# Minimal accent mapping (extend as needed)
LATEX_ACCENTS = {
    r"\\'a": "á",
    r"\\'e": "é",
    r"\\'i": "í",
    r"\\'o": "ó",
    r"\\'u": "ú",
    r"\\`a": "à",
    r"\\`e": "è",
    r"\\`i": "ì",
    r"\\`o": "ò",
    r"\\`u": "ù",
    r'\\"a': "ä",
    r'\\"e': "ë",
    r'\\"i': "ï",
    r'\\"o': "ö",
    r'\\"u': "ü",
    r"\\~n": "ñ",
    r"\\c{c}": "ç",
    r'\&': "&",
    '--': "–",
    r'\ ': " ",
    r'``': "“",
    r"''": "”",
}

def latex_to_html(s):
    if not s:
        return ""

    # Replace simple LaTeX accents
    for latex, char in LATEX_ACCENTS.items():
        s = s.replace(latex, char)
    
    # Convert \emph{} → <em>
    s = re.sub(r'\\emph\{([^{}]+)\}', r'<em>\1</em>', s)

    # Convert \textbf{} → <strong>
    s = re.sub(r'\\textbf\{([^{}]+)\}', r'<strong>\1</strong>', s)

    # Convert \href{...}{...} → <a href="...">...</a>
    s = re.sub(
        r'\\href\{([^{}]+)\}\{([^{}]+)\}',
        r'<a href="\1">\2</a>',
        s
    )

    # Convert \url{...} → <a href="...">...</a>
    s = re.sub(
        r'\\url\{([^{}]+)\}',
        r'<a href="\1">\1</a>',
        s
    )
    
    # Remove outer braces that are just grouping
    s = re.sub(r'\{(.*?)\}', r'\1', s)

    # Escape any remaining HTML characters
    # s = html.escape(s, quote=False)

    # But preserve the HTML we just injected
    s = s.replace("&lt;em&gt;", "<em>").replace("&lt;/em&gt;", "</em>")
    s = s.replace("&lt;strong&gt;", "<strong>").replace("&lt;/strong&gt;", "</strong>")
    s = s.replace("&lt;a (href=.*?)&gt;", r"<a \1>").replace("&lt;/a&gt;", "</a>")

    return s

def group_by_section(entries):
    grouped = defaultdict(list)
    for e in entries:
        grouped[e["_section"]].append(e)

    # Ensure empty sections still exist
    return {s: grouped.get(s, []) for s in SECTION_ORDER}

def load_bibtex():
    entries = []
    for bibfile in sorted(BIB_DIR.glob("*.bib")):
        with open(bibfile) as f:
            db = bibtexparser.load(f)
            for e in db.entries:
                e["_source"] = bibfile.stem
                entries.append(e)
                # print(f"Entry: {e}\n")
    return entries

def entry_to_jsonresume_publication(e):
    # JSON Resume "publications" shape: name, publisher, releaseDate, url, summary
    # We'll keep this conservative and robust across entry types.
    publisher = e.get("journal") or e.get("booktitle") or e.get("publisher") or ""
    year = e.get("year", 0)
    release_date = f"{year}-01-01" if year else ""

    # Title is already HTML-ish if you used latex_to_html; CV usually wants plain text.
    # If you kept raw fields (e.g. _title_raw), prefer that; otherwise strip tags lightly.
    name = e.get("title", "")
    name = name.replace("<em>", "").replace("</em>", "").replace("<strong>", "").replace("</strong>", "")

    summary_bits = []
    if e.get("authors"):
        summary_bits.append(e["authors"])
    if e.get("editor"):
        summary_bits.append(f"Editors: {e['editor']}")
    if e.get("note"):
        summary_bits.append(e["note"])

    return {
        "name": name,
        "publisher": publisher,
        "releaseDate": release_date,
        "url": e.get("url", ""),
        "summary": " — ".join([b for b in summary_bits if b]),
    }

def normalize(entries):
    for e in entries:
        # Ensure we have the bibtex key for anchoring
        # bibtexparser may use 'key' or 'ID' depending on version
        if "key" not in e and "ID" in e:
            e["key"] = e["ID"]
        
        # Year
        e["year"] = int(e.get("year", 0))

        # Authors
        e["authors"] = e.get("author", "").replace(" and ", ", ")

        FIELDS_TO_CLEAN = [
            "title",
            "journal",
            "booktitle",
            "publisher",
            "type",
            "issuetitle",
            "institution",
            "note",
            "howpublished"
        ]

        for field in FIELDS_TO_CLEAN:
            if field in e:
                # Preserve raw field before cleanup
                e[f"_{field}_raw"] = e[field]
                e[field] = latex_to_html(e[field])

        # Normalize DOI and generate its URL
        doi = e.get("doi")
        if doi:
            doi = doi.lower().replace("https://doi.org/", "").strip()
            e["_doi_url"] = f"https://doi.org/{doi}"
        else:
            e["_doi_url"] = None

        # Keywords → normalized set
        raw = e.get("keywords", "")
        e["_keywords"] = {
            k.strip().lower()
            for k in raw.split(",")
            if k.strip()
        }

        # Determine section (first match wins)
        section = "other"
        for s in SECTION_ORDER:
            if s in e["_keywords"]:
                section = s
                break

        e["_section"] = section

    # Sort entries inside sections by year desc
    return sorted(entries, key=lambda e: e["year"], reverse=True)

def main():
    entries = normalize(load_bibtex())
    sections = group_by_section(entries)

    non_empty_sections = [
        s for s in SECTION_ORDER
        if sections.get(s)
    ]

    selected_entries = [
        e for e in entries
        if SELECTED_KEYWORD in e.get("_keywords", set())
    ]

    if EXPORT_SELECTED:
        selected_payload = [entry_to_jsonresume_publication(e) for e in selected_entries]

        SELECTED_OUT_FILE.parent.mkdir(exist_ok=True)
        SELECTED_OUT_FILE.write_text(json.dumps(selected_payload, ensure_ascii=False, indent=2))
    
    env = Environment(loader=FileSystemLoader(TEMPLATE_DIR))
    tpl = env.get_template("publications.html.j2")

    dev_reload = os.environ.get("DEV_RELOAD", "") == "1"
    
    html = tpl.render(
        sections=sections,
        section_order=SECTION_ORDER,
        section_titles=SECTION_TITLES,
        toc_sections=non_empty_sections,
        generated=datetime.now(UTC).strftime("%Y-%m-%d"),
        dev_reload=dev_reload,
    )

    OUT_FILE.parent.mkdir(exist_ok=True)
    OUT_FILE.write_text(html)

if __name__ == "__main__":
    main()
