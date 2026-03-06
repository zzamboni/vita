# Repository Guidelines

## Project Structure & Module Organization
This repository is source-data only.
- `zamboni-vita-full.json`: canonical JSON Resume data.
- `zamboni-pubs.bib`, `zamboni-patents.bib`: publication and patent BibTeX sources.
- `build/`: generated output snapshots (HTML/PDF/Typst); do not treat as authoritative source.

Keep edits focused on root source files and regenerate outputs from those inputs.

## Build, Test, and Development Commands
There is no in-repo build system after removing `mise.toml`; commands below are lightweight validation helpers.
- `jq . zamboni-vita-full.json >/dev/null`
  Validates JSON syntax.
- `rg '^@' zamboni-pubs.bib zamboni-patents.bib`
  Quickly checks BibTeX entries are present and parsable-looking.
- `git diff -- zamboni-vita-full.json zamboni-pubs.bib zamboni-patents.bib`
  Review only source-data changes before commit.

If you regenerate artifacts via an external pipeline, keep that workflow documented in the PR description.

## Coding Style & Naming Conventions
- Use 2-space indentation for JSON and keep formatting consistent across sections.
- Preserve stable key ordering in JSON when possible to reduce diff noise.
- Use consistent BibTeX keys, preferably `lastnameYYYYshorttopic`.
- Name additional data files with lowercase hyphenated patterns (for example, `zamboni-talks.bib`).

## Testing Guidelines
No dedicated unit tests are tracked in this repository.
- Validate JSON syntax and BibTeX entry structure before submitting changes.
- When outputs are regenerated, spot-check `build/<resume-stem>/vita/` for numbering, links, and formatting regressions.
- Include a short validation note in PRs (what you checked and how).

## Commit & Pull Request Guidelines
Recent commits use short, sentence-style summaries (for example, `Removed all CV-building files`, `Moved Bib files to the root dir`).
- Commit messages: one concise line in past tense.
- PRs should include: purpose, files changed, and whether build artifacts were regenerated externally.
- For visible content changes, attach screenshots or mention affected output files.

## Security & Configuration Tips
- Never commit tokens, credentials, or personal API keys.
- Keep sensitive values in environment variables when running external tooling.
- Commit only reproducible source inputs unless artifact updates are intentionally required.
