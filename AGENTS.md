# Repository Guidelines

## Project Structure & Module Organization
- `pubs-src/` holds LaTeX sources, BibTeX data, and images used by the CV/pubs pipelines (e.g., `pubs-src/zamboni-vita.tex`, `pubs-src/**/*.bib`).
- `scripts/` contains build helpers like `render_cv.sh`, `build_publications.py`, and Typst tooling.
- `templates/` holds Jinja2 templates for publications HTML.
- `themes/` contains local JSONResume themes and converters.
- `assets/` stores shared images/badges.
- `build/` is generated output for dev/prod HTML and PDF artifacts.
- Root inputs include `zamboni-vita.json` (JSONResume source), `Tectonic.toml`, and `Makefile`.

## Build, Test, and Development Commands
- `mise run bootstrap`: install Python and Node dependencies into `.venv` and `node_modules`.
- `mise run go-dev`: one-command dev loop (build dev outputs, serve, open, watch).
- `mise run build-dev`: build dev HTML/PDF outputs under `build/zamboni-jsonresume/dev`.
- `mise run build-prod`: build production outputs under `build/zamboni-jsonresume/prod`.
- `make all` or `tectonic -X build`: build LaTeX PDFs.
- `make watch` or `tectonic -X watch -x 'build --open'`: rebuild LaTeX on changes.

## Coding Style & Naming Conventions
- Shell and Python scripts favor strict modes (`set -euo pipefail`) and explicit paths.
- Keep file names descriptive and consistent with existing patterns (e.g., `zamboni-vita.*`, `zamboni-resume.*`).
- Prefer JSONResume keys and BibTeX keywords consistent with current data (`selected`, `refereed`, `patent`).
- No dedicated formatter is configured; keep edits small and match existing style.

## Testing Guidelines
- There is no automated test suite in this repository.
- Validate changes by running the relevant build commands and inspecting outputs in `build/`.

## Commit & Pull Request Guidelines
- Commits in this repo use short, imperative, sentence-style subjects (e.g., `Various improvements`).
- Keep commits focused; if you touch both JSONResume and LaTeX, note it explicitly in the message.
- PRs should describe what changed, which pipeline(s) were run, and include before/after screenshots for HTML changes.

## Security & Configuration Tips
- Credly sync uses public profile data; avoid committing private credentials.
- Generated artifacts in `build/` can be large—avoid committing them unless explicitly requested.
