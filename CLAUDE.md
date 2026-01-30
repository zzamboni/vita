# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains Diego Zamboni's CV/Resume in multiple formats:
1. **LaTeX-based CV** (from org-mode source, using AwesomeCV class) → PDF output
2. **JSONResume-based CV** → HTML output via `resumed` renderer
3. **Publications HTML** → Generated from BibTeX files

The system uses [mise](https://mise.jdx.dev/) as the task runner and build system, [Tectonic](https://tectonic-typesetting.github.io/) for LaTeX compilation, and Python scripts for BibTeX processing.

## Development Workflow

### Initial Setup

```bash
# Install dependencies (Python via uv + npm packages)
mise run bootstrap
```

### Building Documents

**JSONResume CV + Publications (Development with auto-reload):**
```bash
# Build + serve + open + watch for changes (one command)
mise run go-dev

# Or run components separately:
mise run build-dev      # Build dev versions once
mise run serve          # Serve on http://localhost:8008
mise watch build-dev    # Watch and rebuild on changes
```

**JSONResume CV + Publications (Production):**
```bash
mise run build-prod     # Build production versions
mise run open-prod      # Build and open in browser
```

**LaTeX PDF Documents:**
```bash
# Build all PDFs (zamboni-vita.pdf, zamboni-resume.pdf)
make all
# or
tectonic -X build

# Build and watch for changes
make watch
# or
tectonic -X watch -x 'build --open'

# View built PDFs
make view
```

### Common Tasks

```bash
# Update certificates from Credly
mise run certs-update           # Non-expired only
mise run certs-update-all       # Include expired

# Build individual components
mise run render-dev             # CV HTML (dev)
mise run render-prod            # CV HTML (prod)
mise run pubs-dev               # Publications HTML (dev)
mise run pubs-prod              # Publications HTML (prod)

# Devcontainer workflows
mise run dev-up                 # Run in devcontainer (reuse)
mise run dev-rebuild-up         # Rebuild and run devcontainer
```

## Architecture

### Source Files

- **`diego-zamboni-jsonresume.json`**: Primary CV data source in JSONResume format
- **`src/zamboni-vita.tex`**: Full CV LaTeX source (exported from org-mode)
- **`src/zamboni-resume.tex`**: Short resume LaTeX source
- **`src/zamboni-vita-private.tex`**: Private CV version with contact details
- **`src/zamboni-pubs.bib`**: Publications BibTeX database
- **`src/zamboni-patents.bib`**: Patents BibTeX database
- **`templates/publications.html.j2`**: Jinja2 template for publications HTML

### Build Pipeline

**JSONResume Pipeline:**
1. `diego-zamboni-jsonresume.json` → `render_cv.sh` → `resumed render` → HTML output
2. BibTeX files → `build_publications.py` → Jinja2 template → Publications HTML
3. Dev builds inject auto-reload JavaScript; prod builds don't

**LaTeX Pipeline:**
1. `.tex` files → Tectonic (XeTeX/LuaTeX) → PDF output
2. Uses custom AwesomeCV class in `src/awesome-cv.cls`
3. Configuration in `Tectonic.toml` defines output artifacts

### Output Structure

```
build/
├── zamboni-vita/              # LaTeX output (vita PDF)
├── zamboni-resume/            # LaTeX output (resume PDF)
├── zamboni-vita-private/      # LaTeX output (private vita PDF)
└── zamboni-jsonresume/
    ├── dev/                   # Dev builds (with auto-reload)
    │   ├── vita.html
    │   └── publications.html
    └── prod/                  # Production builds (clean)
        ├── vita.html
        └── publications.html
```

### Key Scripts

- **`scripts/render_cv.sh`**: Wrapper for `resumed render` to generate CV HTML from JSON
- **`scripts/build_publications.py`**: Processes BibTeX files and renders publications HTML
  - Parses BibTeX, converts LaTeX markup to HTML
  - Groups publications by section (book, refereed, editorial, etc.)
  - Supports keyword-based filtering (e.g., "selected" publications)
- **`scripts/update-certs-from-credly.py`**: Syncs certificates from Credly API to JSONResume
  - Fetches badges from public Credly profile
  - Preserves non-Credly certificates
  - Filters expired certificates by default
- **`scripts/build_pubs.sh`**: Wrapper that sets environment for publications build

### Configuration Files

- **`mise.toml`**: Defines all build tasks, variables, and dependencies
  - Uses task-based builds with source/output tracking
  - Manages Python virtual environment via uv
  - Defines dev vs prod build modes
- **`Tectonic.toml`**: LaTeX build configuration
  - Defines output documents and their source `.tex` files
  - Specifies TeX bundle location
- **`Makefile`**: Alternative LaTeX build interface
  - Includes `publish` target to deploy to personal website

## Design Patterns

### Dev vs Prod Builds

The JSONResume pipeline maintains separate dev/prod outputs:
- **Dev builds** include auto-reload JavaScript that polls for file changes
- **Prod builds** are clean HTML without any dev tooling
- The `cv-reload-inject` task modifies dev HTML in-place after rendering

### Publications Grouping

Publications are organized using BibTeX keywords:
- Each entry can have keywords like `book`, `refereed`, `patent`, etc.
- The `build_publications.py` script groups entries by first matching keyword
- Section order is defined in `SECTION_ORDER` constant
- Supports "selected" keyword for curated publication lists

### LaTeX-to-HTML Conversion

The publications script includes a `latex_to_html()` function that:
- Converts LaTeX accents to Unicode (e.g., `\\'a` → `á`)
- Transforms `\emph{}` to `<em>`, `\textbf{}` to `<strong>`
- Handles `\href{}{}` and `\url{}` commands
- Preserves semantic markup from BibTeX

## Publishing

The `make publish` target:
1. Copies PDFs to `$(HOME)/Personal/websites/zzamboni.org/static/files/vita`
2. Updates the date in the website's `content/vita.md`
3. Commits and pushes changes to the website git repo

This automates deployment of new CV versions to the personal website.
