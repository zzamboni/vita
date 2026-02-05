#!/usr/bin/env python3
"""Fetch logos for JSONResume work and education entries.

This script tries to download logos from Logo.dev using the URL
domain from JSONResume work and education entries. It stores logos under
assets/logos/ as "<Company Name>.png".
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Iterable, Optional, Tuple


LOGODEV_LOGO = "https://img.logo.dev/{domain}?token={token}"


def load_resume(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def sanitize_filename(name: str) -> str:
    # Keep it readable, remove path separators and characters invalid on Windows.
    name = name.strip()
    name = name.replace("/", "-").replace("\\", "-")
    name = re.sub(r'[<>:"|?*]', "", name)
    name = re.sub(r"\s+", " ", name)
    return name


def extract_domain(url: str) -> Optional[str]:
    if not url:
        return None
    parsed = urllib.parse.urlparse(url)
    if not parsed.netloc:
        return None
    domain = parsed.netloc
    if domain.startswith("www."):
        domain = domain[4:]
    return domain


def iter_work_entries(resume: dict) -> Iterable[Tuple[str, str]]:
    for entry in resume.get("work", []):
        name = entry.get("name", "").strip()
        url = entry.get("url", "").strip()
        if name:
            yield name, url


def iter_education_entries(resume: dict) -> Iterable[Tuple[str, str]]:
    for entry in resume.get("education", []):
        name = entry.get("institution", "").strip() or entry.get("name", "").strip()
        url = entry.get("url", "").strip() or entry.get("website", "").strip()
        if name:
            yield name, url


def _ext_from_content_type(content_type: str) -> Optional[str]:
    if not content_type:
        return None
    content_type = content_type.split(";")[0].strip().lower()
    if content_type == "image/png":
        return ".png"
    if content_type == "image/jpeg":
        return ".jpg"
    if content_type == "image/svg+xml":
        return ".svg"
    if content_type == "image/webp":
        return ".webp"
    return None


def _ext_from_data(data: bytes) -> Optional[str]:
    if not data:
        return None
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png"
    if data.startswith(b"\xff\xd8\xff"):
        return ".jpg"
    if data.startswith(b"GIF87a") or data.startswith(b"GIF89a"):
        return ".gif"
    if data.startswith(b"BM"):
        return ".bmp"
    if data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        return ".webp"
    return None


def download_logo(domain: str, dest: Path, token: str, timeout: int) -> Optional[Path]:
    url = LOGODEV_LOGO.format(domain=domain, token=token)
    req = urllib.request.Request(url, headers={"User-Agent": "cv-logo-fetcher/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            if response.status != 200:
                return None
            data = response.read()
            if not data:
                return None
            ext = _ext_from_content_type(response.headers.get("Content-Type", ""))
            if not ext:
                ext = _ext_from_data(data)
            if not ext:
                ext = dest.suffix or ".png"
            final_dest = dest.with_suffix(ext)
            final_dest.write_bytes(data)
            return final_dest
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError):
        return None


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fetch logos for JSONResume work and education entries."
    )
    parser.add_argument("resume", type=Path, help="Path to JSONResume file")
    parser.add_argument(
        "--logos-dir",
        type=Path,
        default=Path("assets/logos"),
        help="Directory to store logos (default: assets/logos)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be downloaded without writing files",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing logo files",
    )
    parser.add_argument(
        "--token",
        default=os.environ.get("LOGODEV_TOKEN", ""),
        help="Logo.dev API token (or set LOGODEV_TOKEN in environment)",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=10,
        help="Download timeout in seconds (default: 10)",
    )
    args = parser.parse_args()

    resume = load_resume(args.resume)
    args.logos_dir.mkdir(parents=True, exist_ok=True)

    seen = set()
    if not args.token:
        print("error: missing Logo.dev token (use --token or LOGODEV_TOKEN)")
        return 2

    for company, url in iter_work_entries(resume):
        if company in seen:
            continue
        seen.add(company)

        base_filename = sanitize_filename(company)
        dest = args.logos_dir / f"{base_filename}.png"

        if dest.exists() and not args.overwrite:
            print(f"skip (exists): {dest}")
            continue
        existing_alt = None
        for ext in (".jpg", ".jpeg", ".png", ".svg", ".webp"):
            candidate = args.logos_dir / f"{base_filename}{ext}"
            if candidate.exists():
                existing_alt = candidate
                break
        if existing_alt and not args.overwrite:
            print(f"skip (exists): {existing_alt}")
            continue

        domain = extract_domain(url)
        if not domain:
            print(f"skip (no url): {company}")
            continue

        if args.dry_run:
            print(f"would fetch: {company} -> {domain} -> {dest}")
            continue

        saved = download_logo(domain, dest, args.token, args.timeout)
        if saved:
            print(f"saved: {company} -> {saved}")
        else:
            print(f"failed: {company} ({domain})")

    for institution, url in iter_education_entries(resume):
        if institution in seen:
            continue
        seen.add(institution)

        base_filename = sanitize_filename(institution)
        dest = args.logos_dir / f"{base_filename}.png"

        if dest.exists() and not args.overwrite:
            print(f"skip (exists): {dest}")
            continue
        existing_alt = None
        for ext in (".jpg", ".jpeg", ".png", ".svg", ".webp"):
            candidate = args.logos_dir / f"{base_filename}{ext}"
            if candidate.exists():
                existing_alt = candidate
                break
        if existing_alt and not args.overwrite:
            print(f"skip (exists): {existing_alt}")
            continue

        domain = extract_domain(url)
        if not domain:
            print(f"skip (no url): {institution}")
            continue

        if args.dry_run:
            print(f"would fetch: {institution} -> {domain} -> {dest}")
            continue

        saved = download_logo(domain, dest, args.token, args.timeout)
        if saved:
            print(f"saved: {institution} -> {saved}")
        else:
            print(f"failed: {institution} ({domain})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
