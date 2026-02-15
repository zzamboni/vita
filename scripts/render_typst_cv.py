#!/usr/bin/env python3
"""
Convert JSONResume format to Typst CV using brilliant-cv template.

This script reads a JSONResume JSON file and generates a CV using the
brilliant-cv Typst template.

Diego Zamboni <diego@zzamboni.org>, 2026

Coded with help from Claude Code and Codex.
"""

import json
import re
import sys
import urllib.request
from datetime import datetime
from pathlib import Path
import shutil
from typing import Any, Dict, List, Optional

# Config parameters

# Whether to highlight some letters in #cv-section titles
HIGHLIGHTED_TITLES = "false"
# How many letters to highlight, only meaningful if above is true
HIGHLIGHTED_LETTERS = "3"

def convert_markdown_to_typst(text: str) -> str:
    """Convert Markdown formatting to Typst markup."""
    if not text:
        return ""

    def replace_link(match):
        link_text = match.group(1)
        url = match.group(2)
        link_text_processed = convert_markdown_inline(link_text)
        return f'#link("{url}")[{link_text_processed}]'

    text = re.sub(r'\[(.+?)\]\(([^)]+)\)', replace_link, text)
    text = convert_markdown_inline(text)
    return text


def convert_markdown_inline(text: str) -> str:
    """Convert inline Markdown formatting (bold, italic) to Typst."""
    if not text:
        return ""
    text = re.sub(r'\*\*([^*]+)\*\*', r'*\1*', text)
    text = re.sub(r'(?<!\*)\*(?!\*)([^*]+)\*(?!\*)', r'_\1_', text)
    return text


def escape_typst(text: str) -> str:
    """Escape special Typst characters."""
    if not text:
        return ""
    text = text.replace("\\", "\\\\")
    text = text.replace("#", "\\#")
    text = text.replace("<", "\\<")
    text = text.replace(">", "\\>")
    text = text.replace("@", "\\@")
    text = text.replace('"', '\\"')
    return text


def process_text(text: str) -> str:
    """Process text: convert markdown to Typst."""
    if not text:
        return ""
    return convert_markdown_to_typst(text)


PROJECT_SECTION_PREFIX = "projects:"

DEFAULT_SECTIONS = [
    "work",
    "volunteer",
    "education",
    "projects",
    "awards",
    "certificates",
    "publications",
    "skills",
    "languages",
    "interests",
    "references",
]


def normalize_label(label: str) -> str:
    if not label:
        return label
    return label[0].upper() + label[1:]


def get_theme_options(resume_data: Dict[str, Any]) -> Dict[str, Any]:
    return resume_data.get("meta", {}).get("themeOptions", {}) if resume_data else {}


def ordered_project_groups(projects: List[Dict[str, Any]]) -> List[tuple]:
    groups = []
    by_key: Dict[Any, List[Dict[str, Any]]] = {}
    for project in projects:
        key = project.get("type")
        if key not in by_key:
            by_key[key] = []
            groups.append((key, by_key[key]))
        by_key[key].append(project)
    return groups


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
    if start_fmt == end_fmt:
        return f"{start_fmt}"
    else:
        return f"{start_fmt} - {end_fmt}"


def download_image(url: str, base_output_dir: Path, output_dir: Path) -> Optional[str]:
    """Download an image from URL and return local path."""
    if not url:
        return None

    try:
        url_parts = url.split("/")
        if "images.credly.com" in url:
            unique_id = url_parts[-2] if len(url_parts) >= 2 else url_parts[-1]
            filename = f"{unique_id}.png"
        else:
            filename = url_parts[-1]
            if not filename.endswith(('.png', '.jpg', '.jpeg', '.gif', '.svg')):
                filename += '.png'

        output_dir_full = base_output_dir / output_dir
        output_dir_full.mkdir(parents=True, exist_ok=True)
        local_path = output_dir_full / filename

        if not local_path.exists():
            print(f"Downloading {url}...")
            urllib.request.urlretrieve(url, local_path)

        return str(output_dir / filename)
    except Exception as e:
        print(f"Warning: Failed to download {url}: {e}")
        return None


def find_company_logo(name: str, base_output_dir: Path, assets_dir: Path,
                      source_assets_dir: Path) -> Optional[str]:
    """Find a local logo and ensure it exists under the output assets dir."""
    if not name:
        return None

    source_logos_dir = source_assets_dir / "logos"
    output_logos_dir = base_output_dir / assets_dir / "logos"
    for ext in (".png", ".jpg", ".jpeg", ".svg", ".webp", ".gif"):
        filename = f"{name}{ext}"
        candidate = source_logos_dir / filename
        if candidate.exists():
            output_logos_dir.mkdir(parents=True, exist_ok=True)
            dest = output_logos_dir / filename
            if dest.resolve() != candidate.resolve():
                shutil.copy2(candidate, dest)
            return str(assets_dir / "logos" / filename)
    return None

def _personal_info_line(label, value):
    return f'      {label}: "{value}"'

def _personal_info_custom(name, icon, text, url=None):
    return f'''      custom-{name}: (
        awesomeIcon: "{icon or name}",
        text: "{text}"''' + \
        (f',\n        link: "{url}"' if url else "") + "\n      )"

def generate_metadata(basics: Dict[str, Any]) -> str:
    """Generate brilliant-cv metadata dictionary."""
    name = basics.get("name", "")
    name_parts = name.split()
    first_name = basics.get("first_name", name_parts[0] if (len(name_parts)>0) else "")
    last_name = basics.get("last_name", name_parts[1] if (len(name_parts)>1) else "")
    label = basics.get("label", "")
    email = basics.get("email", "")
    url = basics.get("url", "")
    phone = basics.get("phone", "")
    location = basics.get("location", {})

    city = location.get("city", "")
    country = location.get("countryCode", "")

    # Build personal info for brilliant-cv
    personal_info = []
    if email:
        personal_info.append(_personal_info_line('email', email))
    if phone:
        personal_info.append(_personal_info_line('phone', escape_typst(phone)))
    if url:
        url_display = url.replace("https://", "").replace("http://", "")
        # personal_info.append(_personal_info_line('homepage', url_display))
        personal_info.append(_personal_info_custom('homepage', 'home', url_display, url))
    if city:
        personal_info.append(_personal_info_line('location', escape_typst(city)))

    # Add social profiles
    profiles = basics.get("profiles", [])
    for profile in profiles:
        network = profile.get("network", "").lower()
        username = profile.get("username", "")
        networkIcon = profile.get("networkIcon", None)
        url = profile.get("url", None)
        if username:
            if network in ["linkedin", "github"]:
                personal_info.append(_personal_info_line(network, username))
            else:
                personal_info.append(_personal_info_custom(network, networkIcon, username, url))
    personal_str = ",\n".join(personal_info)

    metadata = f'''#let metadata = (
  language: "en",
  name: "{escape_typst(name)}",
  tagline: "{escape_typst(label)}",

  personal: (
    first_name: "{escape_typst(first_name)}",
    last_name: "{escape_typst(last_name)}",
    info: (
{personal_str}
    )
  ),

  layout: (
    awesome_color: "skyblue",
    before_section_skip: "1pt",
    before_entry_skip: "1pt",
    before_entry_description_skip: "1pt",
    paper_size: "a4",
    page_margin: (x: 1.5cm, y: 1.5cm),

    header: (
      display_profile_photo: true,
      profile_photo_radius_pt: "50%",
      info_row_font_size: "8pt",
      header_align: "center"
    ),

    entry: (
      display_logo: true,
      display_entry_society_first: true,
    ),

    footer: (
      display_page_counter: true,
      display_footer: true,
    ),

    fonts: (),
  ),

  inject: (
    inject_ai_prompt: false,
    inject_keywords: false,
    injected_keywords_list: []
  ),

  lang: (
    en: (
      education: "Education",
      professional: "Professional Experience",
      certificates: "Certifications",
      skills: "Skills",
      projects: "Projects",
      activities: "Professional Activities",
      languages: "Languages",
      date_in_present: "Present",
      cv_footer: [ Curriculum Vitae - #datetime.today().display() ],
      header_quote: "{escape_typst(label)}",
    ),
  ),
)
'''

    return metadata


def render_summary(basics: Dict[str, Any], label: str = "Summary") -> str:
    """Render professional summary."""
    summary = basics.get("summary", "")
    if not summary:
        return ""

    paragraphs = [p.strip() for p in summary.split("\n\n") if p.strip()]

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )
    for para in paragraphs:
        output += f"{process_text(para)}\n\n"

    return output


def render_experience(work: List[Dict[str, Any]], base_output_dir: Path, assets_dir: Path,
                      source_assets_dir: Path, label: str = "Work") -> str:
    """Render work experience using brilliant-cv."""
    if not work:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    grouped_work: List[Dict[str, Any]] = []
    for job in work:
        company = job.get("name", "")
        if not grouped_work or grouped_work[-1]["company"] != company:
            grouped_work.append({"company": company, "jobs": []})
        grouped_work[-1]["jobs"].append(job)

    for group in grouped_work:
        jobs = group["jobs"]
        if len(jobs) == 1:
            job = jobs[0]
            company = job.get("name", "")
            position = job.get("position", "")
            start = job.get("startDate", "")
            end = job.get("endDate", "")
            location = job.get("location", "")
            summary = job.get("summary", "")
            highlights = job.get("highlights", [])
            url = job.get("url", "")
            logo_path = find_company_logo(company, base_output_dir, assets_dir, source_assets_dir)

            date_range = format_date_range(start, end)

            # Build description
            desc_parts = []
            if summary:
                desc_parts.append(process_text(summary))
            if highlights:
                for highlight in highlights:
                    desc_parts.append(f"- {process_text(highlight)}")

            description = "\n".join(desc_parts) if desc_parts else ""

            output += f'#cv-entry(\n'
            output += f'  title: [{escape_typst(position)}],\n'
            output += f'  society: ['
            if url:
                output += f'#link("{url}")[{escape_typst(company)}]'
            else:
                output += escape_typst(company)
            output += '],\n'
            output += f'  date: [{date_range}],\n'
            if logo_path:
                output += f'  logo: image("{logo_path}"),\n'
            output += f'  location: [{escape_typst(location)}],\n'
            output += f'  description: [\n    {description}\n  ]\n'
            output += ')\n\n'
            continue

        company = group["company"]
        url = next((job.get("url", "") for job in jobs if job.get("url", "")), "")
        logo_path = find_company_logo(company, base_output_dir, assets_dir, source_assets_dir)
        locations = [job.get("location", "") for job in jobs if job.get("location", "")]
        shared_location = locations[0]

        output += f'#cv-entry-start(\n'
        output += f'  society: ['
        if url:
            output += f'#link("{url}")[{escape_typst(company)}]'
        else:
            output += escape_typst(company)
        output += '],\n'
        if logo_path:
            output += f'  logo: image("{logo_path}"),\n'
        if shared_location:
            output += f'  location: [{escape_typst(shared_location)}],\n'
        output += ')\n#v(4pt)\n\n'

        for job in jobs:
            position = job.get("position", "")
            start = job.get("startDate", "")
            end = job.get("endDate", "")
            summary = job.get("summary", "")
            highlights = job.get("highlights", [])

            date_range = format_date_range(start, end)

            # Build description
            desc_parts = []
            if summary:
                desc_parts.append(process_text(summary))
            if highlights:
                for highlight in highlights:
                    desc_parts.append(f"- {process_text(highlight)}")

            description = "\n".join(desc_parts) if desc_parts else ""

            output += f'#cv-entry-continued(\n'
            output += f'  title: [{escape_typst(position)}],\n'
            output += f'  date: [{date_range}],\n'
            output += f'  description: [\n    {description}\n  ]\n'
            output += ')\n\n'

    return output


def render_education(education: List[Dict[str, Any]], base_output_dir: Path, assets_dir: Path,
                     source_assets_dir: Path, label: str = "Education") -> str:
    """Render education using brilliant-cv."""
    if not education:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for edu in education:
        institution = edu.get("institution", "")
        area = edu.get("area", "")
        study_type = edu.get("studyType", "")
        start = edu.get("startDate", "")
        end = edu.get("endDate", "")
        location = edu.get("location", "")
        summary = edu.get("summary", "")
        url = edu.get("url", "")
        logo_path = find_company_logo(institution, base_output_dir, assets_dir, source_assets_dir)

        date_range = format_date_range(start, end)

        title = study_type
        if area:
            title += f" in {area}"

        description = process_text(summary) if summary else ""

        output += f'#cv-entry(\n'
        output += f'  title: [{escape_typst(title)}],\n'
        output += f'  society: ['
        if url:
            output += f'#link("{url}")[{escape_typst(institution)}]'
        else:
            output += escape_typst(institution)
        output += '],\n'
        output += f'  date: [{date_range}],\n'
        if logo_path:
            output += f'  logo: image("{logo_path}"),\n'
        output += f'  location: [{escape_typst(location)}],\n'
        output += f'  description: [{description}]\n'
        output += ')\n\n'

    return output


def render_skills(skills: List[Dict[str, Any]], label: str = "Skills") -> str:
    """Render skills using brilliant-cv."""
    if not skills:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for skill_group in skills:
        name = skill_group.get("name", "")
        keywords = skill_group.get("keywords", [])

        if not keywords:
            continue

        keywords_str = " #sym.dot.c ".join([escape_typst(kw) for kw in keywords])
        output += f'#cv-skill(type: [{escape_typst(name)}], info: [{keywords_str}])\n#v(6pt)\n\n'

    return output


def render_certificates(certificates: List[Dict[str, Any]], base_output_dir: Path, assets_dir: Path, label: str = "Certificates") -> str:
    """Render certificates using brilliant-cv."""
    if not certificates:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for cert in certificates:
        name = cert.get("name", "")
        issuer = cert.get("issuer", "")
        date = cert.get("date", "")
        url = cert.get("url", "")
        image_url = cert.get("image", "")

        if "See full list" in name:
            if url:
                output += f'Full list available at #link("{url}")[Credly]\n\n'
            continue

        local_image = None
        if image_url:
            local_image = download_image(image_url, base_output_dir, assets_dir / "badges")

        date_fmt = format_date(date) if date else ""

        if local_image:
            output += f'#grid(\n'
            output += f'  columns: (auto, 1fr),\n'
            output += f'  column-gutter: 1em,\n'
            output += f'  align: (center + horizon, left + horizon),\n'
            output += f'  [#image("{local_image}", width: 3em)],\n'
            output += f'  [\n'
            if url:
                output += f'    #link("{url}")[*{escape_typst(name)}*]'
            else:
                output += f'    *{escape_typst(name)}*'
            if issuer:
                output += f', {escape_typst(issuer)}'
            if date_fmt:
                output += f' ({date_fmt})'
            output += '\n  ]\n)\n\n'
        else:
            output += '- '
            if url:
                output += f'#link("{url}")[*{escape_typst(name)}*]'
            else:
                output += f'*{escape_typst(name)}*'
            if issuer:
                output += f', {escape_typst(issuer)}'
            if date_fmt:
                output += f' ({date_fmt})'
            output += '\n\n'

    return output


def render_awards(awards: List[Dict[str, Any]], label: str = "Awards") -> str:
    """Render awards using brilliant-cv."""
    if not awards:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for award in awards:
        title = award.get("title", "")
        date = award.get("date", "")
        awarder = award.get("awarder", "")
        summary = award.get("summary", "")
        url = award.get("url", "")

        date_fmt = format_date(date) if date else ""

        output += '#cv-honor(\n'
        output += f'  date: [{date_fmt}],\n'
        output += f'  title: [{process_text(title)}],\n'
        if awarder:
            output += f'  issuer: [{escape_typst(awarder)}],\n'
        if url:
            output += f'  url: "{url}",\n'
        output += ')\n#v(6pt)\n\n'

        if summary:
            output += f'{process_text(summary)}\n\n'

    return output


def render_projects(projects: List[Dict[str, Any]], label: str = "Projects") -> str:
    """Render projects using brilliant-cv."""
    if not projects:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for project in projects:
        name = project.get("name", "")
        description = project.get("description", "")
        entity = project.get("entity", "")
        start = project.get("startDate", "")
        end = project.get("endDate", "")
        highlights = project.get("highlights", [])
        url = project.get("url", "")
        roles = project.get("roles", [])

        if not name:
            if description:
                output += f"_{process_text(description)}_\n\n"
            continue

        date_range = format_date_range(start, end) if start else ""

        desc_parts = []
        if description:
            desc_parts.append(process_text(description))
        if roles:
            for role in roles:
                desc_parts.append(f"- {process_text(role)}")
        if highlights:
            for highlight in highlights:
                desc_parts.append(f"- {process_text(highlight)}")

        full_description = "\n".join(desc_parts) if desc_parts else ""

        output += f'#cv-entry(\n'
        output += f'  metadata: metadata_alt,\n'
        output += f'  title: ['
        if url:
            output += f'#link("{url}")[{process_text(name)}]'
        else:
            output += process_text(name)
        output += '],\n'
        output += f'  society: [{process_text(entity)}],\n'
        output += f'  date: [{date_range}],\n'
        output += f'  location: [],\n'
        output += f'  description: [\n    {full_description}\n  ]\n'
        output += ')\n\n'

    return output


def render_volunteer(volunteer: List[Dict[str, Any]], label: str = "Volunteer") -> str:
    """Render volunteer activities using brilliant-cv."""
    if not volunteer:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for vol in volunteer:
        org = vol.get("organization", "")
        position = vol.get("position", "")
        start = vol.get("startDate", "")
        end = vol.get("endDate", "")
        url = vol.get("url", "")

        date_range = format_date_range(start, end) if start else ""

        output += f'#cv-entry(\n'
        output += f'  title: [{escape_typst(position)}],\n'
        output += f'  society: ['
        if url:
            output += f'#link("{url}")[{escape_typst(org)}]'
        else:
            output += escape_typst(org)
        output += '],\n'
        output += f'  date: [{date_range}],\n'
        output += f'  location: [],\n'
        output += f'  description: []\n'
        output += ')\n\n'

    return output


def render_publications(publications: List[Dict[str, Any]], label: str = "Publications") -> str:
    """Render publications using brilliant-cv."""
    if not publications:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for pub in publications:
        name = pub.get("name", "")
        publisher = pub.get("publisher", "")
        release_date = pub.get("releaseDate", "")
        url = pub.get("url", "")
        summary = pub.get("summary", "")

        date_fmt = format_date(release_date) if release_date else ""

        output += '#cv-entry(\n'
        output += f'  title: ['
        if url:
            output += f'#link("{url}")[{process_text(name)}]'
        else:
            output += process_text(name)
        output += '],\n'
        output += f'  society: [{escape_typst(publisher)}],\n'
        output += f'  date: [{date_fmt}],\n'
        output += f'  location: [],\n'
        output += f'  description: [{process_text(summary)}]\n'
        output += ')\n\n'

    return output


def render_languages(languages: List[Dict[str, Any]], label: str = "Languages") -> str:
    """Render languages using brilliant-cv."""
    if not languages:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for lang in languages:
        language = lang.get("language", "")
        fluency = lang.get("fluency", "")

        if language and fluency:
            output += f'#cv-skill(type: [{escape_typst(language)}], info: [{escape_typst(fluency)}])\n\n'

    return output


def render_interests(interests: List[Dict[str, Any]], label: str = "Interests") -> str:
    """Render interests using brilliant-cv."""
    if not interests:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for interest in interests:
        name = interest.get("name", "")
        keywords = interest.get("keywords", [])
        keywords_str = " #sym.dot.c ".join([escape_typst(kw) for kw in keywords])
        output += f'#cv-skill(type: [{escape_typst(name)}], info: [{keywords_str}])\n\n'

    return output


def render_references(references: List[Dict[str, Any]], label: str = "References") -> str:
    """Render references."""
    if not references:
        return ""

    output = (
        f'#cv-section("{label}", highlighted: {HIGHLIGHTED_TITLES}, '
        f'letters: {HIGHLIGHTED_LETTERS})\n\n'
    )

    for ref in references:
        name = ref.get("name", "")
        reference = ref.get("reference", "")
        if name and reference:
            output += f'- *{escape_typst(name)}*: {process_text(reference)}\n\n'
        elif name:
            output += f'- *{escape_typst(name)}*\n\n'
        elif reference:
            output += f'- {process_text(reference)}\n\n'

    return output


def render_sections(resume_data: Dict[str, Any], base_output_dir: Path, assets_dir: Path,
                    source_assets_dir: Path) -> str:
    """Render resume sections in the desired order."""
    theme_options = get_theme_options(resume_data)
    sections = theme_options.get("sections")
    sections_is_default = not isinstance(sections, list) or not sections
    if sections_is_default:
        sections = DEFAULT_SECTIONS

    section_labels = theme_options.get("sectionLabels", {})
    projects_by_type = bool(theme_options.get("projectsByType"))
    projects = resume_data.get("projects", [])
    has_project_overrides = (not sections_is_default) and any(
        isinstance(section, str) and (section == "projects" or section.startswith(PROJECT_SECTION_PREFIX))
        for section in sections
    )

    def label_for(key: str, fallback: str) -> str:
        return normalize_label(section_labels.get(key, fallback))

    output = ""
    for section in sections:
        if section == "work":
            output += render_experience(
                resume_data.get("work", []),
                base_output_dir,
                assets_dir,
                source_assets_dir,
                label=label_for("work", "Work"),
            )
            continue
        if section == "volunteer":
            output += render_volunteer(resume_data.get("volunteer", []), label=label_for("volunteer", "Volunteer"))
            continue
        if section == "education":
            output += render_education(
                resume_data.get("education", []),
                base_output_dir,
                assets_dir,
                source_assets_dir,
                label=label_for("education", "Education"),
            )
            continue
        if section == "projects":
            if projects_by_type and sections_is_default:
                for type_key, items in ordered_project_groups(projects):
                    if not items:
                        continue
                    if type_key is None:
                        output += render_projects(items, label_for("projects", "Projects"))
                    else:
                        label_key = f"{PROJECT_SECTION_PREFIX}{type_key}"
                        output += render_projects(items, label_for(label_key, str(type_key)))
                continue

            if projects_by_type and has_project_overrides:
                typeless = [p for p in projects if not p.get("type")]
                if typeless:
                    output += render_projects(typeless, label_for("projects", "Projects"))
                continue

            output += render_projects(projects, label_for("projects", "Projects"))
            continue
        if isinstance(section, str) and section.startswith(PROJECT_SECTION_PREFIX):
            if not projects_by_type:
                continue
            type_key = section[len(PROJECT_SECTION_PREFIX):].strip()
            if not type_key:
                continue
            items = [p for p in projects if p.get("type") == type_key]
            if not items:
                continue
            output += render_projects(items, label_for(section, type_key))
            continue
        if section == "awards":
            output += render_awards(resume_data.get("awards", []), label=label_for("awards", "Awards"))
            continue
        if section == "certificates":
            output += render_certificates(
                resume_data.get("certificates", []),
                base_output_dir,
                assets_dir,
                label=label_for("certificates", "Certificates"),
            )
            continue
        if section == "publications":
            output += render_publications(
                resume_data.get("publications", []),
                label=label_for("publications", "Publications"),
            )
            continue
        if section == "skills":
            output += render_skills(resume_data.get("skills", []), label=label_for("skills", "Skills"))
            continue
        if section == "languages":
            output += render_languages(resume_data.get("languages", []), label=label_for("languages", "Languages"))
            continue
        if section == "interests":
            output += render_interests(resume_data.get("interests", []), label=label_for("interests", "Interests"))
            continue
        if section == "references":
            output += render_references(resume_data.get("references", []), label=label_for("references", "References"))
            continue

    return output

def generate_typst_cv(resume_data: Dict[str, Any], base_output_dir: Path, assets_dir: Path,
                      source_assets_dir: Path) -> str:
    """Generate Typst CV using brilliant-cv template."""

    basics = resume_data.get("basics", {})
    image_url = basics.get("image", "")

    # Download profile photo
    photo_path = None
    if image_url:
        photo_path = download_image(image_url, base_output_dir, assets_dir / "profile")

    # Start with imports and metadata
    output = """// Professional CV generated from JSONResume
// Using brilliant-cv template

#import "@preview/brilliant-cv:3.1.2": *

/// Add the title of a section
///
/// NOTE: If the language is non-Latin, the title highlight will not be sliced.
///
/// This is a copy of the function from the brilliant-cv package, but making it sticky
/// to prevent orphan headings.
///
/// - title (str): The title of the section.
/// - highlighted (bool): Whether the first n letters will be highlighted in accent color.
/// - letters (int): The number of first letters of the title to highlight.
/// - metadata (array): (optional) the metadata read from the TOML file.
/// - awesome-colors (array): (optional) the awesome colors of the CV.
/// -> content
#let cv-section(
  title,
  highlighted: true,
  letters: 3,
  metadata: none,
  // New parameter names (recommended)
  awesome-colors: none,
  // Old parameter names (deprecated, for backward compatibility)
  awesomeColors: _awesome-colors,
) = context {
  let metadata = if metadata != none { metadata } else { cv-metadata.get() }
  // Backward compatibility logic (remove this block when deprecating)
  let awesome-colors = if awesome-colors != none {
    awesome-colors
  } else {
    // TODO: Add deprecation warning in future version
    // Currently Typst doesn't have a standard warning mechanism for user functions
    awesomeColors
  }

  let lang = metadata.language
  let non-latin = _is-non-latin(lang)
  let before-section-skip = _get-layout-value(metadata, "before_section_skip", 1pt)
  let accent-color = _set-accent-color(awesome-colors, metadata)
  let highlighted-text = title.slice(0, letters)
  let normal-text = title.slice(letters)

  let section-title-style(str, color: black) = {
    text(size: 16pt, weight: "bold", fill: color, str)
  }

  v(before-section-skip)
  block(
    sticky: true,
    [#if non-latin {
      section-title-style(title, color: accent-color)
    } else {
      if highlighted {
        section-title-style(highlighted-text, color: accent-color)
        section-title-style(normal-text, color: black)
      } else {
        section-title-style(title, color: black)
      }
    }
    #h(2pt)
    #box(width: 1fr, line(stroke: 0.9pt, length: 100%))]
  )
}

"""

    # Add metadata
    output += generate_metadata(basics)
    output += '''
#let metadata_alt = metadata + (
  layout: metadata.layout + (
    entry: metadata.layout.entry + (
      display_entry_society_first: false,
    )
  )
)
'''
    output += "\n"

    # Apply brilliant-cv template
    if photo_path:
        output += f'''#show: cv.with(
  metadata,
  profile-photo: image("{photo_path}"),
)

'''
    else:
        output += '''#show: cv.with(
  metadata,
)

'''

    # Add content sections
    output += render_summary(basics)
    output += render_sections(resume_data, base_output_dir, assets_dir, source_assets_dir)

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

    with open(input_file, 'r', encoding='utf-8') as f:
        resume_data = json.load(f)

    assets_dir = Path("assets")
    source_assets_dir = Path("assets")

    if output_file:
        base_output_dir = output_file.parent
    else:
        base_output_dir = Path.cwd()

    assets_dir_full = base_output_dir / assets_dir

    typst_content = generate_typst_cv(
        resume_data,
        base_output_dir,
        assets_dir,
        source_assets_dir,
    )

    if output_file:
        output_file.parent.mkdir(parents=True, exist_ok=True)
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(typst_content)
        print(f"Generated Typst CV: {output_file}")
    else:
        print(typst_content)


if __name__ == "__main__":
    main()
