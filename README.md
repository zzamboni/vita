# My CV

This repository is where I keep the source files for [my CV](https://zzamboni.org/vita/) and [my list of publications](https://zzamboni.org/vita/publications/). I use [JSON Resume](https://jsonresume.org/) for the CV and BibTeX for the publications.

Over time, I've separated the source data, the tools that generate PDFs, and the website that displays everything. This makes it easier for me to update one piece without having to rebuild the whole setup.

## How it works

There are four repositories involved:

- **[vita](https://github.com/zzamboni/vita)** (this one) is where I edit my CV and bibliography.
- **[resume-toolkit](https://github.com/zzamboni/resume-toolkit)** is my containerized toolkit for turning those files into PDFs, a publications JSON file, and an aggregated BibTeX file. It can generate standalone HTML too.
- **[hugo-jsonresume](https://github.com/zzamboni/hugo-jsonresume)** is the Hugo module I use to render the CV and publications directly on my website. It includes support for the Blowfish theme.
- **[zzamboni.org](https://github.com/zzamboni/zzamboni.org)** is my Hugo website, where the generated data and downloads end up.

For the website, I run `resume-toolkit` with `--no-html`. There's no point generating another set of HTML pages when `hugo-jsonresume` already handles [`/vita/`](https://zzamboni.org/vita/) and [`/vita/publications/`](https://zzamboni.org/vita/publications/). I still generate both PDFs, the publications JSON and the BibTeX file.

```text
My JSON Resume + BibTeX files (vita)
                 |
                 v
        resume-toolkit --no-html
                 |
                 +-- Resume + publications JSON --> zzamboni.org/data/jsonresume/
                 +-- PDFs + publications BibTeX --> zzamboni.org/static/vita/
                                                        |
                                                        v
                                                 hugo-jsonresume
                                                /vita/ + /vita/publications/
```

## The source files

I keep a couple of versions of my CV:

- `zamboni-vita-general.json` is the one I normally publish on my website.
- `zamboni-vita-full.json` is a more complete version, which I can select when needed.

The publications live in `zamboni-pubs.bib` and `zamboni-patents.bib`. The JSON Resume files specify which bibliographies to use.

Anything under `build/` is generated. The sync script also creates a temporary `zamboni-vita.json` so the exported files keep their existing names. Neither belongs in Git.

## Updating my website

I have two ways of doing this, depending on whether I want to update a local checkout or open a PR on GitHub.

### Copy the results to my local website checkout

I use [mise](https://mise.jdx.dev/) to keep the commands short:

```sh
mise run sync-website
```

This builds the default CV and copies the JSON, PDFs and BibTeX into my local `zzamboni.org` checkout. It uses the `deploy_dir` variable in `mise.toml` to find the website (currently `../websites/zzamboni.org/static/vita/`). I can override that with `DEPLOY_DIR` or pass `--website-dir` directly to `scripts/sync-website.sh`.

If I want to use my full CV instead:

```sh
mise run sync-website --resume zamboni-vita-full.json
```

This needs the `resume-toolkit` `build-resume.sh` wrapper (in my `PATH` or specified with `VITA_BUILD_SCRIPT`) and Docker or Podman.

The script only copies the files it knows about. **It doesn't commit or push anything.** I can also use `--dry-run` to see what would change, or `--skip-build` to reuse an existing build.

### Update the website through GitHub

Most of the time, I'd rather let GitHub Actions generate the files and open a PR for me. Once I've **committed and pushed my changes to `vita/main`**, I run:

```sh
mise run trigger-website-sync
```

Or, for the full CV:

```sh
mise run trigger-website-sync zamboni-vita-full.json
```

This uses the [GitHub CLI](https://cli.github.com/) (`gh`). I can also [start the workflow from GitHub](https://github.com/zzamboni/vita/actions/workflows/sync-website.yml) and choose which JSON file to use.

The workflow builds the CV with `--no-html`, compares the results against `zzamboni.org/main`, and opens a PR when the resume JSON, publications JSON or BibTeX has changed. **If only the PDFs are different, it skips the PR**, since generated PDF files can change even when their contents haven't. When there's a real data change, the PR includes any updated PDFs as well.

I review and merge the PR myself. The workflow puts the PR link (or a note saying nothing changed) in the GitHub Actions run summary. Merging the PR into my website's `main` branch takes care of the normal deployment.

### One-time GitHub setup

To let the workflow write to my website repository, I store a fine-grained GitHub token as `WEBSITE_SYNC_TOKEN` in **vita → Settings → Secrets and variables → Actions**. It needs Contents and Pull requests read/write access to `zzamboni/zzamboni.org`.

For the exact file mappings and more options, I've put the details in [the website sync notes](docs/website-sync.md). The [resume-toolkit repository](https://github.com/zzamboni/resume-toolkit) has its own instructions for building standalone versions of my CV.
