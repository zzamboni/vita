# Vita

Source data and publishing workflow for [Diego Zamboni's CV](https://zzamboni.org/vita/) and [publications](https://zzamboni.org/vita/publications/).

This repository contains the editable [JSON Resume](https://jsonresume.org/) documents and BibTeX sources. It **does not own the website's HTML templates** or treat generated files as canonical. The published CV is assembled from several independently maintained repositories.

## How the pieces fit together

| Repository | Responsibility |
| --- | --- |
| **[zzamboni/vita](https://github.com/zzamboni/vita)** (this repository) | JSON Resume and BibTeX source files; local synchronization script and GitHub Actions dispatch |
| **[zzamboni/resume-toolkit](https://github.com/zzamboni/resume-toolkit)** | Containerized build pipeline producing CV/publications PDFs, publications JSON and aggregated BibTeX (and standalone HTML when requested) |
| **[zzamboni/hugo-jsonresume](https://github.com/zzamboni/hugo-jsonresume)** | Reusable Hugo module rendering the CV and publications pages from JSON data; supports the Blowfish theme used by the site |
| **[zzamboni/zzamboni.org](https://github.com/zzamboni/zzamboni.org)** | Hugo website, module configuration, imported JSON data and downloadable PDF/BibTeX files |

On the website, `hugo-jsonresume` renders `/vita/` and `/vita/publications/`. The synchronization build runs `resume-toolkit` with **`--no-html`**, since Hugo produces the web pages; the pipeline still generates both PDFs, publications JSON and BibTeX.

```text
vita (JSON Resume + BibTeX)
       |
       v
resume-toolkit --no-html
       |
       +-- resume JSON --------------------> zzamboni.org/data/jsonresume/
       +-- publications JSON -------------> zzamboni.org/data/jsonresume/
       +-- CV/publications PDFs ----------> zzamboni.org/static/vita/
       +-- aggregated publications BibTeX -> zzamboni.org/static/vita/
                                              |
                                              v
                                       hugo-jsonresume
                                      /vita/ + /vita/publications/
```

## Source files

- `zamboni-vita-general.json`: **default** resume used when synchronizing with the website.
- `zamboni-vita-full.json`: more comprehensive resume variant, selectable when needed.
- `zamboni-pubs.bib` and `zamboni-patents.bib`: source bibliography files, referenced from the JSON Resume configuration.

Generated output under `build/` and the temporary `zamboni-vita.json` are ignored by Git. Edit the source JSON and BibTeX files rather than generated output.

## Working locally

The following tasks use [mise](https://mise.jdx.dev/). Local builds require the `resume-toolkit` `build-resume.sh` wrapper (on `PATH` or configured via `VITA_BUILD_SCRIPT`) and Docker or Podman.

### Build and copy into a local website checkout

```sh
mise run sync-website
```

The default destination is derived from `deploy_dir` in `mise.toml` (currently `../websites/zzamboni.org/static/vita/`), so the script finds the website repository root automatically. Set `DEPLOY_DIR` to override it, or call `scripts/sync-website.sh --website-dir /path/to/zzamboni.org` directly.

Choose another input resume:

```sh
mise run sync-website --resume zamboni-vita-full.json
```

The local script copies only the expected JSON/PDF/BibTeX outputs. It **does not commit or push** changes. Use `--dry-run` to preview differences or `--skip-build` to reuse existing build output. Its default selected input is `zamboni-vita-general.json`.

### Open a website update PR using GitHub Actions

After editing the source files, **commit and push to `vita/main` first**, then dispatch the workflow:

```sh
mise run trigger-website-sync
```

Or select another JSON Resume:

```sh
mise run trigger-website-sync zamboni-vita-full.json
```

This task requires the authenticated [GitHub CLI](https://cli.github.com/) (`gh`). You can also run [Sync vita to zzamboni.org](https://github.com/zzamboni/vita/actions/workflows/sync-website.yml) manually in GitHub Actions, where the resume filename is an input.

The workflow:

1. Checks out this repository and `zzamboni.org/main`.
2. Builds the chosen resume using `resume-toolkit --no-html` and synchronizes the five approved website files.
3. Checks changes to resume JSON, publications JSON and BibTeX. **PDF-only differences do not trigger a PR**, since generated PDF bytes can vary without a source-content change.
4. When JSON or BibTeX changed, opens a **reviewable PR against `zzamboni.org/main`**, including any changed PDFs. It does not auto-merge.
5. Shows the PR link (or the no-change explanation) in the GitHub Actions run summary.

Merging the PR updates the website's content and downloads and follows its normal deployment process.

### GitHub Actions credential

The `vita` repository must have an Actions secret named `WEBSITE_SYNC_TOKEN`: a fine-grained personal access token with **Contents: read/write** and **Pull requests: read/write** permissions for `zzamboni/zzamboni.org`. Store it in **vita → Settings → Secrets and variables → Actions**, because the workflow runs here and writes to the other repository.

For detailed output paths, prerequisites and script options, see **[Website synchronization guide](docs/website-sync.md)**. The toolkit's separate [README](https://github.com/zzamboni/resume-toolkit) covers standalone CV builds and output-format switches.
