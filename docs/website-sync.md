# Synchronizing vita with zzamboni.org

The canonical inputs are `zamboni-vita-full.json`, `zamboni-pubs.bib`,
and `zamboni-patents.bib` in this repository. Website rendering is owned by
`zzamboni/zzamboni.org`; resume-toolkit creates the downloads and the
publications JSON data. HTML rendering is disabled using **only** `--no-html`.

## Locally

Place checkouts of `vita` and `zzamboni.org` next to each other, or
specify the destination explicitly:

```sh
bash scripts/sync-website.sh --website-dir ../zzamboni.org
```

`build-resume.sh` must be available in PATH, or specify
`--build-script /path/to/build-resume.sh` (or set `VITA_BUILD_SCRIPT`).
The wrapper uses Docker or Podman with the published resume-toolkit image
(default: `ghcr.io/zzamboni/resume-toolkit:latest`); the image must support
`--no-html`. Set `VITA_PIPELINE_IMAGE` to use another local image.

Use `--dry-run` to preview the file differences without writing to the
website, or `--skip-build` to reuse an existing output directory.
The script never commits or pushes; review the website checkout and commit
there if desired. `zamboni-vita.json` is a temporary, gitignored input
created for the output stem and removed after the build.

The script updates exactly these files:

| Source | zzamboni.org destination |
| --- | --- |
| `zamboni-vita-full.json` | `data/jsonresume/resume.json` |
| `build/zamboni-vita/vita/publications/zamboni-vita-pubs.json` | `data/jsonresume/publications.json` |
| `build/zamboni-vita/vita/zamboni-vita.pdf` | `static/vita/zamboni-vita.pdf` |
| `build/zamboni-vita/vita/publications/zamboni-vita-pubs.pdf` | `static/vita/publications/zamboni-vita-pubs.pdf` |
| `build/zamboni-vita/vita/publications/zamboni-vita-pubs.bib` | `static/vita/publications/zamboni-vita-pubs.bib` |

Other files, including logos, site templates, and unrelated static assets,
are not deleted or overwritten. Missing required files fail the sync.

## GitHub Actions

The manually triggered workflow is
[Sync vita to zzamboni.org](../.github/workflows/sync-website.yml).
Run it from the `vita` repository's **Actions** tab. It checks out the
website's `staging` branch, uses the same script, and opens a pull request
against `staging` only if output files changed. It never auto-merges.

Before running, configure a `vita` **Actions secret**
named `WEBSITE_SYNC_TOKEN`: a fine-grained GitHub personal access token
for `zzamboni/zzamboni.org` with **Contents: Read and write** and
**Pull requests: Read and write**. The default vita `GITHUB_TOKEN`
cannot push to a different repository.

The workflow uses the current `main` branch of resume-toolkit's host
wrapper and the published `latest` container image. Publish a
resume-toolkit release containing `--no-html` before running it.
No version bump or release is performed by this workflow.

Running the workflow creates a review PR; only merging into the website's
`staging` branch initiates its normal staging deploy. A production
promotion remains a separate manual decision.
