# Repository Guidelines

## Project Structure & Module Organization
- `scripts/` contains the build pipeline and helpers:
  - `scripts/run_pipeline.sh` (main pipeline entrypoint used by `mise build`)
  - `scripts/render_cv.sh`, `scripts/render_typst_cv.py`, `scripts/build_publications.py`
  - `scripts/fetch_company_logos.py`, `scripts/update-certs-from-credly.py`
- `templates/` contains publications HTML templates.
- `themes/` contains the local JSONResume theme.
- `pubs-src/` contains BibTeX/LaTeX publications inputs.
- `assets/` contains profile images, logos, and icon assets.
- `docker/` contains container entrypoint/runtime helpers.
- `build-resume.sh` is the user-facing local wrapper around the Docker image.
- `build/` is generated output and should generally not be committed.

## Build, Test, and Development Commands
- Primary user interface:
  - `./build-resume.sh <resume.json> [bibfiles...] [--out <dir>] [--watch] [--serve]`
  - `./build-resume.sh fetch-logos <resume.json> [--overwrite] [--dry-run] [--token <token>]`
  - `./build-resume.sh update-certs <username> <resume.json> [flags]`
  - `./build-resume.sh tasks` (show exposed task list)
- Direct `mise` tasks (user-facing):
  - `mise run build ...` (alias: `mise run pipeline ...`)
  - `mise run fetch-logos ...`
  - `mise run update-certs ...`
- Internal/helper tasks exist but are hidden in `mise tasks ls`.

## Coding Style & Naming Conventions
- Shell and Python scripts favor strict modes (`set -euo pipefail`) and explicit paths.
- Prefer generic names and avoid project/person-specific hardcoding where possible.
- Prefer JSONResume keys and BibTeX keywords consistent with current data (`selected`, `refereed`, `patent`, etc.).
- No dedicated formatter is configured; keep edits small and match existing style.

## Testing Guidelines
- There is no automated test suite in this repository.
- Validate by running the relevant pipeline command and checking generated files in `build/`.
- For Docker-facing changes, validate via `build-resume.sh` (not only host-side `mise`).

## Commit & Pull Request Guidelines
- Commits in this repo use short, imperative, sentence-style subjects (e.g., `Various improvements`).
- Keep commits focused and mention pipeline/tooling impacts explicitly.
- PRs should include:
  - what changed
  - which commands were run to validate
  - before/after screenshots for HTML/UI changes when relevant

## Security & Configuration Tips
- Credly sync uses public profile data; avoid committing private credentials.
- Logo download uses `LOGODEV_TOKEN`; do not commit tokens.
- Generated artifacts in `build/` can be large—avoid committing them unless explicitly requested.
