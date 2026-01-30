#!/usr/bin/env python3
"""
Update JSONResume "certificates" section from a Credly public badges feed.

- Input:  Credly username + path to JSONResume file
- Output: Overwrites the JSONResume file (or writes --output)
- Keeps existing non-Credly certificates
- Updates/replaces Credly certificates
- Adds optional "image" field (badge template image URL) for visuals
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime, date
from typing import Any, Dict, List, Optional
from urllib.request import Request, urlopen

CREDLY_USER_BADGES_URL = "https://www.credly.com/users/{username}/badges.json"
CREDLY_BADGE_PUBLIC_URL = "https://www.credly.com/badges/{badge_id}/public_url"

CREDLY_HOST_RE = re.compile(r"^https?://(www\.)?credly\.com/badges/", re.IGNORECASE)


def http_get_json(url: str) -> Any:
    req = Request(url, headers={"User-Agent": "jsonresume-credly-sync/1.0"})
    with urlopen(req) as r:
        charset = r.headers.get_content_charset() or "utf-8"
        return json.loads(r.read().decode(charset))


def iso_to_yyyy_mm_dd(value: Optional[str]) -> Optional[str]:
    """Best-effort: parse ISO-like strings and return YYYY-MM-DD."""
    if not value or not isinstance(value, str):
        return None

    v = value.strip()
    # Common Credly fields can be like "2019-04-08T00:00:00.000Z"
    # or "2019-04-08"
    for fmt in (
        "%Y-%m-%d",
        "%Y-%m-%dT%H:%M:%S.%fZ",
        "%Y-%m-%dT%H:%M:%SZ",
        "%Y-%m-%dT%H:%M:%S.%f%z",
        "%Y-%m-%dT%H:%M:%S%z",
    ):
        try:
            dt = datetime.strptime(v, fmt)
            return dt.date().isoformat()
        except ValueError:
            pass

    # Last resort: pull leading YYYY-MM-DD if present
    m = re.match(r"^(\d{4}-\d{2}-\d{2})", v)
    return m.group(1) if m else None


def pick_first(*vals: Optional[str]) -> Optional[str]:
    for v in vals:
        if v and isinstance(v, str) and v.strip():
            return v.strip()
    return None


def issuer_from_badge(b: Dict[str, Any]) -> Optional[str]:
    """
    Credly feed (as in badges.json) often stores issuer as:
      - issuer.summary: "issued by <Name>"
      - issuer.entities[0].entity.name: "<Name>"
    Same structure may exist at badge_template.issuer.
    """
    bt = b.get("badge_template") or {}

    issuer = b.get("issuer") or {}
    bt_issuer = bt.get("issuer") or {}

    def issuer_name_from(obj: Dict[str, Any]) -> Optional[str]:
        if not isinstance(obj, dict):
            return None

        # 1) Prefer the structured org name if present
        ents = obj.get("entities")
        if isinstance(ents, list) and ents:
            ent0 = ents[0]
            if isinstance(ent0, dict):
                entity = ent0.get("entity")
                if isinstance(entity, dict):
                    name = entity.get("name")
                    if isinstance(name, str) and name.strip():
                        return name.strip()

        # 2) Fall back to summary: "issued by X"
        summary = obj.get("summary")
        if isinstance(summary, str) and summary.strip():
            s = summary.strip()
            s = re.sub(r"^issued by\s+", "", s, flags=re.IGNORECASE).strip()
            return s or None

        return None

    # Try both issuer locations; keep your other fallbacks as last resort
    issuing_org = bt.get("issuing_organization") or {}
    owner = bt.get("owner") or {}
    org = bt.get("organization") or {}

    return pick_first(
        issuer_name_from(issuer),
        issuer_name_from(bt_issuer),
        issuing_org.get("name"),
        org.get("name"),
        owner.get("name"),
        bt.get("organization_name"),
    )

def image_from_badge(b: Dict[str, Any]) -> Optional[str]:
    bt = b.get("badge_template") or {}
    # Prefer template image for consistent visuals
    return pick_first(
        bt.get("image_url"),
        b.get("image_url"),
    )


def public_url_from_badge(b: Dict[str, Any]) -> str:
    # Some payloads include "public_url"
    pu = b.get("public_url")
    if isinstance(pu, str) and pu.strip():
        return pu.strip()

    badge_id = b.get("id")
    if not badge_id or not isinstance(badge_id, str):
        raise ValueError("Badge item missing 'id' and no 'public_url' provided.")
    return CREDLY_BADGE_PUBLIC_URL.format(badge_id=badge_id)

def badge_is_expired(b: Dict[str, Any]) -> bool:
    """
    Return True iff the badge has expires_at_date and it is in the past.
    Badges with no expiration date are considered non-expiring.
    """
    today = date.today()
    expires = pick_first(
        b.get("expires_at_date"),
        (b.get("badge_template") or {}).get("expires_at_date"),
    )

    if not isinstance(expires, str) or not expires:
        return False  # non-expiring cert

    try:
        exp_date = date.fromisoformat(expires)
    except ValueError:
        return False  # fail safe

    return exp_date < today

def badge_is_probably_certification(b: Dict[str, Any]) -> bool:
    """
    Optional filter: Credly has different badge types. Fields vary, so we do best-effort.
    If we can't tell, default to True.
    """
    bt = b.get("badge_template") or {}
    # Known-ish fields used in some payloads
    candidates = [
        bt.get("badge_type"),
        bt.get("type_category"),
        bt.get("type"),
        bt.get("category"),
    ]
    text = " ".join([c for c in candidates if isinstance(c, str)]).lower()
    if not text:
        return True
    return ("cert" in text) or ("certification" in text)


def normalize_key(name: Optional[str], issuer: Optional[str]) -> str:
    """
    Used to match existing entries; keeps it stable even if URLs differ.
    """
    def norm(s: Optional[str]) -> str:
        if not s:
            return ""
        s = s.strip().lower()
        s = re.sub(r"\s+", " ", s)
        return s

    return f"{norm(name)}|||{norm(issuer)}"


def build_cert_from_badge(b: Dict[str, Any]) -> Dict[str, Any]:
    bt = b.get("badge_template") or {}
    name = pick_first(bt.get("name"), b.get("title"), b.get("name"))
    issuer = issuer_from_badge(b)
    url = public_url_from_badge(b)

    # Credly commonly has issued_at / issued_on / issued_at_date etc.
    date_str = pick_first(
        iso_to_yyyy_mm_dd(b.get("issued_at")),
        iso_to_yyyy_mm_dd(b.get("issued_on")),
        iso_to_yyyy_mm_dd(b.get("issue_date")),
        iso_to_yyyy_mm_dd(b.get("created_at")),
    )

    cert: Dict[str, Any] = {}
    if name:
        cert["name"] = name
    if issuer:
        cert["issuer"] = issuer
    cert["url"] = url
    if date_str:
        cert["date"] = date_str

    img = image_from_badge(b)
    if img:
        cert["image"] = img  # non-standard but great for visuals

    return cert


def is_credly_certificate_entry(cert: Dict[str, Any]) -> bool:
    url = cert.get("url")
    return (not isinstance(url, str)) or bool(CREDLY_HOST_RE.match(url.strip()))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("username", help="Credly username (e.g., diego-zamboni)")
    ap.add_argument("jsonresume", help="Path to JSONResume file (e.g., diego-zamboni-jsonresume.json)")
    ap.add_argument("--output", help="Write to a different file instead of overwriting")
    ap.add_argument("--include-non-cert-badges", action="store_true",
                    help="Include all badges, even if not classified as certifications")
    ap.add_argument("--include-expired", action="store_true",
                    help="Include expired certificates (default: only non-expired)")
    ap.add_argument("--sort", choices=["date_desc", "date_asc", "name"], default="date_desc",
                    help="Sorting for Credly-derived certificates (default: date_desc)")
    args = ap.parse_args()

    feed_url = CREDLY_USER_BADGES_URL.format(username=args.username)
    feed = http_get_json(feed_url)

    badges: List[Dict[str, Any]] = []
    # Common structure: { data: [ ... ], metadata: { ... } }
    if isinstance(feed, dict) and isinstance(feed.get("data"), list):
        badges = [b for b in feed["data"] if isinstance(b, dict)]
    elif isinstance(feed, list):
        badges = [b for b in feed if isinstance(b, dict)]
    else:
        raise RuntimeError(f"Unexpected Credly feed format from {feed_url}")

    if not args.include_non_cert_badges:
        badges = [b for b in badges if badge_is_probably_certification(b)]

    if not args.include_expired:
        badges = [b for b in badges if not badge_is_expired(b)]
        
    credly_certs = [build_cert_from_badge(b) for b in badges]

    # Sort Credly-derived entries
    def cert_date(c: Dict[str, Any]) -> date:
        d = c.get("date")
        if isinstance(d, str) and re.match(r"^\d{4}-\d{2}-\d{2}$", d):
            return datetime.strptime(d, "%Y-%m-%d").date()
        return date.min

    if args.sort == "date_desc":
        credly_certs.sort(key=cert_date, reverse=True)
    elif args.sort == "date_asc":
        credly_certs.sort(key=cert_date)
    elif args.sort == "name":
        credly_certs.sort(key=lambda c: (c.get("name") or "").lower())

    # Load JSONResume
    with open(args.jsonresume, "r", encoding="utf-8") as f:
        resume = json.load(f)

    existing = resume.get("certificates")
    if not isinstance(existing, list):
        existing = []

    # Keep non-Credly entries as-is
    preserved = [c for c in existing if isinstance(c, dict) and not is_credly_certificate_entry(c)]

    # Merge/update Credly entries:
    # - If an existing Credly entry has same URL OR same (name, issuer) key, replace it with fresh data.
    existing_credly = [c for c in existing if isinstance(c, dict) and is_credly_certificate_entry(c)]
    by_url: Dict[str, Dict[str, Any]] = {}
    by_key: Dict[str, Dict[str, Any]] = {}
    for c in existing_credly:
        u = c.get("url")
        if isinstance(u, str) and u.strip():
            by_url[u.strip()] = c
        by_key[normalize_key(c.get("name"), c.get("issuer"))] = c

    merged_credly: List[Dict[str, Any]] = []
    for c in credly_certs:
        u = c.get("url", "").strip()
        k = normalize_key(c.get("name"), c.get("issuer"))

        # If matched, we "update" by taking the new object
        if u and u in by_url:
            merged_credly.append(c)
        elif k and k in by_key:
            merged_credly.append(c)
        else:
            merged_credly.append(c)

    # Final certificates list
    resume["certificates"] = preserved + merged_credly

    out_path = args.output or args.jsonresume
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(resume, f, ensure_ascii=False, indent=4)
        f.write("\n")

    print(f"Updated {out_path}")
    print(f"- Preserved non-Credly certificates: {len(preserved)}")
    print(f"- Synced Credly certificates:       {len(merged_credly)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
