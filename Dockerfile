FROM node:24-bookworm-slim AS base

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python-is-python3 \
    python3-pip \
    python3-venv \
    fontconfig \
    libgraphite2-3 \
    fonts-roboto \
    ca-certificates \
    curl \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

FROM base AS runtime
ENV XDG_CACHE_HOME=/opt/vita-cache
ENV TECTONIC_CACHE_DIR=/opt/vita-cache/tectonic
ENV MISE_DATA_DIR=/opt/vita-cache/mise
ENV NPM_CONFIG_UPDATE_NOTIFIER=false

RUN cd /tmp \
  && curl --proto '=https' --tlsv1.2 -fsSLo typst.tar.xz \
    https://github.com/typst/typst/releases/download/v0.14.0/typst-x86_64-unknown-linux-musl.tar.xz \
  && tar -xJf typst.tar.xz \
  && install -m 0755 typst-x86_64-unknown-linux-musl/typst /usr/local/bin/typst \
  && rm -rf /tmp/typst.tar.xz /tmp/typst-x86_64-unknown-linux-musl

RUN cd /tmp \
  && curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net | sh \
  && install -m 0755 /tmp/tectonic /usr/local/bin/tectonic \
  && rm -f /tmp/tectonic

RUN cd /tmp \
    && curl --proto '=https' --tlsv1.2 -fsSLo biber.tar.gz \
       'https://sourceforge.net/projects/biblatex-biber/files/biblatex-biber/2.17/binaries/Linux/biber-linux_x86_64.tar.gz' \
    && tar -xzf biber.tar.gz \
    && chmod +x biber \
    && cp biber /usr/bin/biber \
    && rm -f /tmp/biber.tar.gz /tmp/biber

WORKDIR /opt/vita-toolkit

RUN mkdir -p /opt/vita-cache \
  && chmod -R a+rwx /opt/vita-cache

RUN mkdir -p /usr/local/share/fonts
COPY fonts/ /usr/local/share/fonts/
COPY pubs-assets/ ./pubs-assets/
RUN fc-cache -f

ARG PREWARM_CACHE=0
RUN if [ "$PREWARM_CACHE" = "1" ]; then \
      mkdir -p "$TECTONIC_CACHE_DIR" /tmp/tectonic-prime/fonts; \
      cp /opt/vita-toolkit/pubs-assets/awesome-cv.cls /tmp/tectonic-prime/; \
      cp -a /opt/vita-toolkit/pubs-assets/fonts/. /tmp/tectonic-prime/fonts/; \
      printf '%s\n' \
        '@article{prime-entry,' \
        '  title={Prime},' \
        '  author={Prime, Example},' \
        '  journal={Prime Journal},' \
        '  year={2024},' \
        '  keyword={other}' \
        '}' > /tmp/tectonic-prime/publications.bib; \
      printf '%s\n' \
        '\documentclass[12pt,a4paper]{awesome-cv}' \
        '\usepackage[defernumbers=true,style=numeric,sorting=ydnt,backend=biber]{biblatex}' \
        '\addbibresource{publications.bib}' \
        '\defbibheading{cvbibsection}[\bibname]{\cvsubsection{#1}}' \
        '\renewcommand*{\bodyfontlight}{\sourcesanspro}' \
        '\renewcommand*{\bibfont}{\paragraphstyle}' \
        '\renewcommand*{\entrylocationstyle}[1]{{\fontsize{10pt}{1em}\bodyfontlight\slshape\color{awesome} #1}}' \
        '\renewcommand*{\subsectionstyle}{\entrytitlestyle}' \
        '\renewcommand*{\headerquotestyle}[1]{{\fontsize{8pt}{1em}\bodyfont #1}}' \
        '\fontdir[fonts/]' \
        '\colorlet{awesome}{awesome-concrete}' \
        '\colorizelinks[awesome-skyblue]' \
        '\begin{document}' \
        '\makecvfooter{\today}{Prime Author~~~·~~~Publications\\\textup{\tiny Online at \href{https://example.invalid/vita/publications}{\nolinkurl{example.invalid/vita/publications}}}}{\thepage}' \
        '\cvsubsection{Prime Author}' \
        '{\tiny\ttfamily warm-cache}' \
        '{\tiny $x$ \small $x$}' \
        '{\fontsize{9pt}{9pt}\selectfont\ttfamily warm-cache-9pt}' \
        '{\fontsize{9pt}{9pt}\selectfont $x$}' \
        '\cvsection{Publications}' \
        '\nocite{*}' \
        '\printbibliography[keyword=other, heading=cvbibsection, title=Other Publications]' \
        '\end{document}' > /tmp/tectonic-prime/publications.tex; \
      cd /tmp/tectonic-prime && tectonic publications.tex; \
      (echo '#import "@preview/brilliant-cv:3.1.2"'; echo '#import "@preview/fontawesome:0.6.0"') | typst compile - /tmp/tectonic-prime/prime-typst.pdf; \
      rm -rf /tmp/tectonic-prime; \
    fi \
  && chmod -R a+rwX /opt/vita-cache

COPY mise.toml requirements.txt package.json package-lock.json ./
COPY themes/jsonresume-theme-even/ ./themes/jsonresume-theme-even/

RUN curl https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh \
  && mise trust /opt/vita-toolkit/mise.toml \
  && mise install \
  && HUSKY=0 NPM_CONFIG_IGNORE_SCRIPTS=true mise run bootstrap \
  && npm cache clean --force

COPY scripts/ ./scripts/
COPY templates/ ./templates/
COPY assets/ ./assets/
COPY docker/entrypoint.sh /usr/local/bin/vita-pipeline
RUN  chmod +x /usr/local/bin/vita-pipeline

RUN chmod +x /opt/vita-toolkit/scripts/run_pipeline.sh

WORKDIR /work

ENTRYPOINT ["/usr/local/bin/vita-pipeline"]
CMD ["tasks"]
