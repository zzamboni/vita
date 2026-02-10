#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
from pathlib import Path


PUB_REF_RE = re.compile(r'\[\[(\d+)\]\]\(([^)\s]*#pub-([^)]+))\)')
HTML_REF_RE = re.compile(
    r'<a[^>]*href="#pub-([^"]+)"[^>]*class="ref-number"[^>]*data-ref-number="(\d+)"',
    re.IGNORECASE,
)


def build_id_map(html_path: Path) -> dict[str, str]:
    html = html_path.read_text(encoding="utf-8")
    mapping: dict[str, str] = {}
    for pub_id, number in HTML_REF_RE.findall(html):
        mapping[pub_id] = number
    return mapping


def update_json_text(text: str, mapping: dict[str, str]) -> tuple[str, int, int]:
    replaced = 0
    missing = 0

    def repl(match: re.Match[str]) -> str:
        nonlocal replaced, missing
        old_num, link, pub_id = match.groups()
        new_num = mapping.get(pub_id)
        if not new_num:
            missing += 1
            return match.group(0)
        if new_num == old_num:
            return match.group(0)
        replaced += 1
        return f"[[{new_num}]]({link})"

    updated = PUB_REF_RE.sub(repl, text)
    return updated, replaced, missing


def main() -> int:
    parser = argparse.ArgumentParser(description="Update publication reference numbers in zamboni-vita.json.")
    parser.add_argument(
        "--html",
        default="build/zamboni-jsonresume/dev/vita/publications/index.html",
        help="Path to publications HTML file.",
    )
    parser.add_argument(
        "--json",
        default="zamboni-vita.json",
        help="Path to JSON resume file to update.",
    )
    args = parser.parse_args()

    html_path = Path(args.html)
    json_path = Path(args.json)

    if not html_path.exists():
        raise SystemExit(f"HTML file not found: {html_path}")
    if not json_path.exists():
        raise SystemExit(f"JSON file not found: {json_path}")

    mapping = build_id_map(html_path)
    if not mapping:
        raise SystemExit(f"No publication IDs found in {html_path}")

    original = json_path.read_text(encoding="utf-8")
    updated, replaced, missing = update_json_text(original, mapping)

    if updated != original:
        json_path.write_text(updated, encoding="utf-8")

    print(f"Updated references: {replaced}")
    if missing:
        print(f"Unmatched references: {missing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
