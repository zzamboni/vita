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
import copy

#logging.getLogger("bibtexparser").setLevel(logging.ERROR)

BIB_DIR = Path(os.environ.get("PUBS_BIB_DIR", "pubs-src"))
OUT_FILE = Path(os.environ.get("PUBS_HTML", "dist/publications.html"))
TEMPLATE_DIR = Path("templates")
PUBS_OUT_DIR = Path(os.environ.get("PUBS_OUT_DIR", "")) if os.environ.get("PUBS_OUT_DIR") else None

EXPORT_SELECTED = False
SELECTED_KEYWORD = "selected"
SELECTED_OUT_FILE = Path("site/selected-publications.json")

SECTION_ORDER = [
    "book",
    "editorial",
    "thesis",
    "refereed",
    "techreport",
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

FA_SVG_DIR = Path("assets/fontawesome")
_ICON_CACHE = {}


def normalize_icon_name(icon):
    if not icon:
        return ""
    raw = str(icon)
    cleaned = (
        raw.replace("fa-", " ")
        .replace("fa ", " ")
        .replace("fa-solid ", " ")
        .replace("fa-regular ", " ")
        .replace("fa-brands ", " ")
        .strip()
    )
    parts = cleaned.split()
    return parts[-1] if parts else cleaned


def load_icon_svg(icon_name: str) -> str:
    if not icon_name:
        return ""
    if icon_name in _ICON_CACHE:
        return _ICON_CACHE[icon_name]
    if not FA_SVG_DIR.exists():
        _ICON_CACHE[icon_name] = ""
        return ""
    filename = f"{icon_name}.svg"
    for style in ("solid", "regular", "brands"):
        candidate = FA_SVG_DIR / style / filename
        if candidate.exists():
            _ICON_CACHE[icon_name] = candidate.read_text()
            return _ICON_CACHE[icon_name]
    for candidate in FA_SVG_DIR.rglob(filename):
        _ICON_CACHE[icon_name] = candidate.read_text()
        return _ICON_CACHE[icon_name]
    _ICON_CACHE[icon_name] = ""
    return ""

def parse_legacy_links(env_var: str):
    raw = os.environ.get(env_var, "")
    if not raw:
        return []

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        logging.warning("Invalid %s JSON payload; ignoring.", env_var)
        return []

    if isinstance(data, dict):
        return [{"label": str(k), "url": str(v)} for k, v in data.items()]

    if isinstance(data, list):
        links = []
        for item in data:
            if isinstance(item, dict) and "label" in item and "url" in item:
                links.append({"label": str(item["label"]), "url": str(item["url"])})
            elif isinstance(item, (list, tuple)) and len(item) == 2:
                links.append({"label": str(item[0]), "url": str(item[1])})
        return links

    return []



def parse_floating_links(env_var: str):
    raw = os.environ.get(env_var, "")
    if not raw:
        return []

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        logging.warning("Invalid %s JSON payload; ignoring.", env_var)
        return []

    if not isinstance(data, list):
        return []

    links = []
    for item in data:
        if not isinstance(item, dict):
            continue
        name = item.get("name")
        url = item.get("url")
        icon = item.get("icon")
        if name and url and icon:
            icon_key = normalize_icon_name(icon)
            links.append(
                {
                    "name": str(name),
                    "url": str(url),
                    "icon": str(icon),
                    "icon_svg": load_icon_svg(icon_key),
                }
            )
    return links


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

def clean_bib_entry(entry):
    cleaned = {}
    for k, v in entry.items():
        if k.startswith("_"):
            continue
        if v is None:
            continue
        if isinstance(v, (str, int, float)):
            cleaned[k] = str(v)
    return cleaned

def write_combined_bib(raw_entries, sections):
    if not PUBS_OUT_DIR:
        return
    PUBS_OUT_DIR.mkdir(parents=True, exist_ok=True)
    combined_path = PUBS_OUT_DIR / "zamboni-pubs.bib"
    raw_by_key = {
        (e.get("key") or e.get("ID")): e for e in raw_entries if (e.get("key") or e.get("ID"))
    }
    chunks = []
    for section_key in SECTION_ORDER:
        section_entries = sections.get(section_key, [])
        if not section_entries:
            continue
        section_title = SECTION_TITLES.get(section_key, section_key)
        chunks.append(f"% ====== {section_title} ======\n")
        section_db = bibtexparser.bibdatabase.BibDatabase()
        entries_for_section = []
        for e in section_entries:
            key = e.get("key") or e.get("ID")
            if not key:
                continue
            raw = raw_by_key.get(key, e)
            entries_for_section.append(clean_bib_entry(raw))
        section_db.entries = entries_for_section
        chunks.append(bibtexparser.dumps(section_db).strip())
        chunks.append("")
    combined_path.write_text("\n".join(chunks).strip() + "\n")

def group_by_section(entries):
    grouped = defaultdict(list)
    for e in entries:
        grouped[e["_section"]].append(e)

    def sort_key(entry):
        year = entry.get("year")
        if year:
            return (int(year), "")
        date = entry.get("date") or ""
        return (0, str(date))

    # Ensure empty sections still exist, and sort each section by year (desc)
    return {
        s: sorted(grouped.get(s, []), key=sort_key, reverse=True)
        for s in SECTION_ORDER
    }

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

def normalize(raw_entries):
    entries = copy.deepcopy(raw_entries)
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
    raw_entries = load_bibtex()
    entries = normalize(raw_entries)
    sections = group_by_section(entries)
    write_combined_bib(raw_entries, sections)

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
        floating_links=parse_floating_links("PUBS_LINKS"),
    )

    OUT_FILE.parent.mkdir(exist_ok=True)
    OUT_FILE.write_text(html)

if __name__ == "__main__":
    main()
