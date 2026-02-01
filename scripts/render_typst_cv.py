#!/usr/bin/env python3
"""
Convert JSONResume format to Typst CV format.

This script reads a JSONResume JSON file and generates a professional-looking
CV in Typst format, which can then be compiled to PDF.
"""

import json
import re
import sys
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


def convert_markdown_to_typst(text: str) -> str:
    """Convert Markdown formatting to Typst markup."""
    if not text:
        return ""

    # Convert Markdown links [text](url) to Typst #link("url")[text]
    # Handle nested brackets in link text by using a more sophisticated approach
    def replace_link(match):
        link_text = match.group(1)
        url = match.group(2)
        # Recursively process the link text for other markdown (but not links)
        link_text_processed = convert_markdown_inline(link_text)
        return f'#link("{url}")[{link_text_processed}]'

    # Use a regex that allows brackets within the link text
    # Match [ followed by anything (including brackets) followed by ]( and then the URL
    text = re.sub(r'\[(.+?)\]\(([^)]+)\)', replace_link, text)

    # Convert inline formatting
    text = convert_markdown_inline(text)

    return text


def convert_markdown_inline(text: str) -> str:
    """Convert inline Markdown formatting (bold, italic) to Typst."""
    if not text:
        return ""

    # Convert **bold** to *bold* (Typst uses single asterisk for bold)
    text = re.sub(r'\*\*([^*]+)\*\*', r'*\1*', text)

    # Convert *italic* to _italic_ (Typst uses underscore for italic)
    # But we need to be careful not to convert * that are part of bold
    text = re.sub(r'(?<!\*)\*(?!\*)([^*]+)\*(?!\*)', r'_\1_', text)

    return text


def escape_typst(text: str) -> str:
    """Escape special Typst characters in text that's already been processed."""
    if not text:
        return ""
    # Escape special characters for Typst
    # Note: Don't escape *, _, [, ] if they're part of Typst markup from markdown conversion
    text = text.replace("\\", "\\\\")
    text = text.replace("#", "\\#")
    text = text.replace("<", "\\<")
    text = text.replace(">", "\\>")
    text = text.replace("@", "\\@")
    return text


def process_text(text: str) -> str:
    """Process text: convert markdown to Typst, then escape remaining special chars."""
    if not text:
        return ""
    # First convert markdown to Typst markup
    text = convert_markdown_to_typst(text)
    # Then escape only the characters that should be escaped
    # We need a more selective escape that doesn't break Typst markup
    return text


def format_date(date_str: Optional[str]) -> str:
    """Format date string for display."""
    if not date_str:
        return "Present"
    try:
        date = datetime.fromisoformat(date_str)
        return date.strftime("%b %Y")
    except:
        return date_str


def format_date_range(start: Optional[str], end: Optional[str]) -> str:
    """Format date range."""
    start_fmt = format_date(start)
    end_fmt = format_date(end) if end else "Present"
    return f"{start_fmt} -- {end_fmt}"


def render_header(basics: Dict[str, Any], assets_dir: Path) -> str:
    """Render the CV header with name and contact info."""
    name = basics.get("name", "")
    label = basics.get("label", "")
    email = basics.get("email", "")
    url = basics.get("url", "")
    location = basics.get("location", {})
    image_url = basics.get("image", "")

    city = location.get("city", "")
    country = location.get("countryCode", "")
    location_str = f"{city}, {country}" if city and country else city or country

    # Download profile image if available
    local_image = None
    if image_url:
        local_image = download_image(image_url, assets_dir / "profile")

    # Icon mapping
    icon_map = {
        "email": "envelope",
        "url": "globe",
        "location": "location-dot"
    }

    # Build contact info items with icons
    contact_items = []
    if email:
        contact_items.append(f"#fa-icon(\"envelope\") #link(\"mailto:{email}\")[{escape_typst(email)}]")
    if url:
        url_display = url.replace("https://", "").replace("http://", "")
        contact_items.append(f"#fa-icon(\"globe\") #link(\"{url}\")[{escape_typst(url_display)}]")
    if location_str:
        contact_items.append(f"#fa-icon(\"location-dot\") {location_str}")

    contact_line = " #text(fill: gray)[•] ".join(contact_items)

    # Social network icon mapping
    social_icons = {
        "LinkedIn": "linkedin",
        "Linkedin": "linkedin",
        "GitHub": "github",
        "Github": "github",
        "Twitter": "twitter",
        "Bluesky": "bluesky",
        "Leanpub": "leanpub"
    }

    # Add profiles/social links
    profiles = basics.get("profiles", [])
    social_line = ""
    if profiles:
        profile_links = []
        for profile in profiles:
            network = profile.get("network", "")
            url = profile.get("url", "")
            username = profile.get("username", "")
            if url and network:
                icon = social_icons.get(network, "link")
                profile_links.append(f"#fa-icon(\"{icon}\") #link(\"{url}\")[{escape_typst(network)}]")

        if profile_links:
            # Align left if we have a photo, center otherwise
            social_line =  f"""{" #text(fill: gray)[•] ".join(profile_links)}
"""
    
    # Header with optional profile photo
    if local_image:
        # Layout with photo on the left, text info on the right
        output = f"""// Header with profile photo
#grid(
  columns: (80%, 20%),
  column-gutter: 1.5em,
  align: (center, center),
  [
    #set par(spacing: 0.3em)
    #v(1em)
    #text(size: 28pt, weight: "thin")[{escape_typst(name)}]

    #v(0.3em)
    #text(size: 10pt, fill: gray)[#smallcaps[{process_text(label)}]]

    #v(0.5em)
    #text(size: 8pt)[{contact_line}]

    #v(0.5em)
    #text(size: 8pt)[{social_line}]
  ],
  [
    // Circular profile photo
    #box(
      clip: true,
      radius: 50%,
      stroke: 0pt + rgb("#3498db"),
      width: 8em,
      height: 8em,
      image(\"{local_image}\", width: 8em, height: 8em, fit: "cover")
    )
  ]
)

#v(0.8em)

"""
    else:
        # Centered layout without photo
        output = f"""// Header
#align(center)[
    #set par(spacing: 0.3em)
    #v(1em)
    #text(size: 28pt, weight: "thin")[{escape_typst(name)}]

    #v(0.3em)
    #text(size: 10pt, fill: gray)[#smallcaps[{process_text(label)}]]

    #v(0.5em)
    #text(size: 8pt)[{contact_line}]

    #v(0.5em)
    #text(size: 8pt)[{social_line}]
]

#v(0.8em)

"""


    return output


def render_summary(basics: Dict[str, Any]) -> str:
    """Render the professional summary."""
    summary = basics.get("summary", "")
    if not summary:
        return ""

    # Split into paragraphs
    paragraphs = [p.strip() for p in summary.split("\n\n") if p.strip()]

    output = """== Summary

"""

    for para in paragraphs:
        output += f"{process_text(para)}\n\n"

    return output


def render_experience(work: List[Dict[str, Any]]) -> str:
    """Render work experience section."""
    if not work:
        return ""

    output = """== Professional Experience

"""

    for job in work:
        company = job.get("name", "")
        position = job.get("position", "")
        start = job.get("startDate", "")
        end = job.get("endDate", "")
        location = job.get("location", "")
        summary = job.get("summary", "")
        highlights = job.get("highlights", [])
        url = job.get("url", "")

        date_range = format_date_range(start, end)

        # Company name (with link if available)
        if url:
            company_display = f"#link(\"{url}\")[*{escape_typst(company)}*]"
        else:
            company_display = f"*{escape_typst(company)}*"

        output += f"""#grid(
  columns: (1fr, auto),
  [{company_display}],
  [#text(fill: gray)[{date_range}]]
)

"""

        # Position and location
        position_line = f"_{escape_typst(position)}_"
        if location:
            position_line += f" #text(fill: gray)[• {escape_typst(location)}]"

        output += f"{position_line}\n\n"

        # Summary
        if summary:
            output += f"{process_text(summary)}\n\n"

        # Highlights
        if highlights:
            for highlight in highlights:
                output += f"- {process_text(highlight)}\n"
            output += "\n"

    return output


def render_education(education: List[Dict[str, Any]]) -> str:
    """Render education section."""
    if not education:
        return ""

    output = """== Education

"""

    for edu in education:
        institution = edu.get("institution", "")
        area = edu.get("area", "")
        study_type = edu.get("studyType", "")
        start = edu.get("startDate", "")
        end = edu.get("endDate", "")
        location = edu.get("location", "")
        summary = edu.get("summary", "")
        url = edu.get("url", "")

        date_range = format_date_range(start, end)

        # Institution name (with link if available)
        if url:
            institution_display = f"#link(\"{url}\")[*{escape_typst(institution)}*]"
        else:
            institution_display = f"*{escape_typst(institution)}*"

        output += f"""#grid(
  columns: (1fr, auto),
  [{institution_display}],
  [#text(fill: gray)[{date_range}]]
)

"""

        # Degree and area
        degree_line = f"_{escape_typst(study_type)}"
        if area:
            degree_line += f" in {escape_typst(area)}"
        degree_line += "_"

        if location:
            degree_line += f" #text(fill: gray)[• {escape_typst(location)}]"

        output += f"{degree_line}\n\n"

        # Summary (e.g., thesis info)
        if summary:
            output += f"{process_text(summary)}\n\n"

    return output


def render_skills(skills: List[Dict[str, Any]]) -> str:
    """Render skills section."""
    if not skills:
        return ""

    output = """== Skills

"""

    for skill_group in skills:
        name = skill_group.get("name", "")
        keywords = skill_group.get("keywords", [])

        if not keywords:
            continue

        output += f"*{escape_typst(name)}*: "
        output += ", ".join([escape_typst(kw) for kw in keywords])
        output += "\n\n"

    return output


def download_image(url: str, output_dir: Path) -> Optional[str]:
    """Download an image from URL and return local path."""
    if not url:
        return None

    try:
        # Create assets directory if it doesn't exist
        output_dir.mkdir(parents=True, exist_ok=True)

        # Use a unique filename based on the URL path
        # Extract the unique ID from Credly URLs (e.g., 6430efe4-0ac0-4df6-8f1b-9559d8fcdf27)
        url_parts = url.split("/")
        if "images.credly.com" in url:
            # Credly URLs have format: /images/<uuid>/image.png
            unique_id = url_parts[-2] if len(url_parts) >= 2 else url_parts[-1]
            filename = f"{unique_id}.png"
        else:
            filename = url_parts[-1]
            if not filename.endswith(('.png', '.jpg', '.jpeg', '.gif', '.svg')):
                filename += '.png'

        local_path = output_dir / filename

        # Download if not already cached
        if not local_path.exists():
            print(f"Downloading {url}...")
            urllib.request.urlretrieve(url, local_path)

        return str(local_path)
    except Exception as e:
        print(f"Warning: Failed to download {url}: {e}")
        return None


def render_certificates(certificates: List[Dict[str, Any]], assets_dir: Path) -> str:
    """Render certificates and certifications section."""
    if not certificates:
        return ""

    output = """== Certifications

"""

    for cert in certificates:
        name = cert.get("name", "")
        issuer = cert.get("issuer", "")
        date = cert.get("date", "")
        url = cert.get("url", "")
        image_url = cert.get("image", "")

        # Skip the "See full list" entry
        if "See full list" in name:
            if url:
                output += f"Full list available at #link(\"{url}\")[Credly]\n\n"
            continue

        # Download image if available
        local_image = None
        if image_url:
            local_image = download_image(image_url, assets_dir / "badges")

        # Add certificate with badge image
        if local_image:
            output += f"""#grid(
  columns: (auto, 1fr),
  column-gutter: 0.8em,
  align: (center, left),
  [#image(\"{local_image}\", width: 3em)],
  [
"""
        else:
            output += "- "

        if url:
            cert_text = f"#link(\"{url}\")[*{escape_typst(name)}*]"
        else:
            cert_text = f"*{escape_typst(name)}*"

        if issuer:
            cert_text += f", {escape_typst(issuer)}"

        if date:
            cert_text += f" ({format_date(date)})"

        if local_image:
            output += f"    {cert_text}\n  ]\n)\n\n"
        else:
            output += f"{cert_text}\n"

    output += "\n"
    return output


def render_awards(awards: List[Dict[str, Any]]) -> str:
    """Render awards and honors section."""
    if not awards:
        return ""

    output = """== Awards & Honors

"""

    for award in awards:
        title = award.get("title", "")
        awarder = award.get("awarder", "")
        date = award.get("date", "")
        summary = award.get("summary", "")

        award_line = f"- *{escape_typst(title)}*"

        if awarder:
            award_line += f", {escape_typst(awarder)}"

        if date:
            award_line += f" ({format_date(date)})"

        output += f"{award_line}\n"

        if summary:
            output += f"  {process_text(summary)}\n"

    output += "\n"
    return output


def render_languages(languages: List[Dict[str, Any]]) -> str:
    """Render languages section."""
    if not languages:
        return ""

    output = """== Languages

"""

    lang_items = []
    for lang in languages:
        language = lang.get("language", "")
        fluency = lang.get("fluency", "")

        if language and fluency:
            lang_items.append(f"*{escape_typst(language)}*: {escape_typst(fluency)}")

    output += " #text(fill: gray)[|] ".join(lang_items) + "\n\n"

    return output


def render_projects(projects: List[Dict[str, Any]], project_type: str) -> str:
    """Render projects of a specific type."""
    filtered = [p for p in projects if p.get("type") == project_type]

    if not filtered:
        return ""

    # Map project types to section titles
    type_titles = {
        "Research": "Research Projects",
        "Software": "Software Projects",
        "Professional Highlights": "Professional Highlights",
        "Program Committees and Boards": "Program Committees & Editorial Boards",
        "Advising": "Student Advising",
        "Teaching": "Teaching Experience"
    }

    title = type_titles.get(project_type, project_type)

    output = f"""== {title}

"""

    for project in filtered:
        name = project.get("name", "")
        description = project.get("description", "")
        entity = project.get("entity", "")
        start = project.get("startDate", "")
        end = project.get("endDate", "")
        highlights = project.get("highlights", [])
        url = project.get("url", "")
        roles = project.get("roles", [])

        # Skip the publications reference in Research type
        if project_type == "Research" and not name:
            if description:
                output += f"_{process_text(description)}_\n\n"
            continue

        # Project name/title
        if name:
            if url:
                output += f"*#link(\"{url}\")[{process_text(name)}]*"
            else:
                output += f"*{process_text(name)}*"

            # Add date range if available
            if start:
                date_range = format_date_range(start, end)
                output += f" #text(fill: gray)[({date_range})]"

            output += "\n\n"

        # Entity/organization
        if entity:
            output += f"_{process_text(entity)}_\n\n"

        # Roles (for committees/advising)
        if roles:
            for role in roles:
                output += f"- {process_text(role)}\n"
            output += "\n"

        # Description
        if description and name:  # Only if we have a name (avoid duplication)
            output += f"{process_text(description)}\n\n"

        # Highlights
        if highlights:
            for highlight in highlights:
                output += f"- {process_text(highlight)}\n"
            output += "\n"

    return output


def render_volunteer(volunteer: List[Dict[str, Any]]) -> str:
    """Render volunteer/professional activities section."""
    if not volunteer:
        return ""

    output = """== Professional Activities

"""

    for vol in volunteer:
        org = vol.get("organization", "")
        position = vol.get("position", "")
        start = vol.get("startDate", "")
        end = vol.get("endDate", "")
        url = vol.get("url", "")

        if url:
            output += f"- *{escape_typst(position)}*, #link(\"{url}\")[{escape_typst(org)}]"
        else:
            output += f"- *{escape_typst(position)}*, {escape_typst(org)}"

        if start:
            date_range = format_date_range(start, end)
            output += f" ({date_range})"

        output += "\n"

    output += "\n"
    return output


def generate_typst_cv(resume_data: Dict[str, Any], assets_dir: Path) -> str:
    """Generate complete Typst CV from JSONResume data."""

    # Start with document setup
    output = """// Professional CV generated from JSONResume
// Compiled with Typst

#import "@preview/fontawesome:0.6.0": fa-icon

#set document(
  title: "{name} - Curriculum Vitae",
  author: "{name}",
)

#set page(
  paper: "a4",
  margin: (x: 1.5cm, y: 1.5cm),
)

#set text(
  font: "Roboto",
  size: 9pt,
  lang: "en",
)

#set par(
  justify: true,
  leading: 0.65em,
)

#show heading.where(level: 2): it => {{
  set text(size: 14pt, weight: "bold")
  v(0.8em)
  block[
    #text(fill: rgb("#2c3e50"))[#it.body]
    #v(-0.3em)
    #line(length: 100%, stroke: 0.5pt + rgb("#3498db"))
  ]
  v(0.5em)
}}

#show link: it => {{
  set text(fill: rgb("#2980b9"))
  underline(it)
}}

""".format(name=resume_data.get("basics", {}).get("name", ""))

    # Add content sections
    output += render_header(resume_data.get("basics", {}), assets_dir)
    output += render_summary(resume_data.get("basics", {}))
    output += render_experience(resume_data.get("work", []))
    output += render_education(resume_data.get("education", []))

    # Skills and certifications
    output += render_skills(resume_data.get("skills", []))
    output += render_certificates(resume_data.get("certificates", []), assets_dir)
    output += render_awards(resume_data.get("awards", []))
    output += render_languages(resume_data.get("languages", []))

    # Projects sections
    projects = resume_data.get("projects", [])
    for project_type in ["Professional Highlights", "Research", "Software",
                         "Program Committees and Boards", "Advising", "Teaching"]:
        output += render_projects(projects, project_type)

    # Volunteer/professional activities
    output += render_volunteer(resume_data.get("volunteer", []))

    return output


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: render_typst_cv.py <jsonresume-file> [output-file]")
        sys.exit(1)

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else None

    if not input_file.exists():
        print(f"Error: Input file {input_file} not found")
        sys.exit(1)

    # Read JSONResume data
    with open(input_file, 'r', encoding='utf-8') as f:
        resume_data = json.load(f)

    # Determine assets directory (relative to output file or current directory)
    if output_file:
        assets_dir = output_file.parent / "assets"
    else:
        assets_dir = Path.cwd() / "assets"

    # Generate Typst CV
    typst_content = generate_typst_cv(resume_data, assets_dir)

    # Write output
    if output_file:
        output_file.parent.mkdir(parents=True, exist_ok=True)
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(typst_content)
        print(f"Generated Typst CV: {output_file}")
    else:
        print(typst_content)


if __name__ == "__main__":
    main()
