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

RUN mkdir -p /root/.local/share/fonts
COPY fonts/ /root/.local/share/fonts/
COPY requirements-docker.txt package.json package-lock.json ./
COPY scripts/ ./scripts/
COPY templates/ ./templates/
COPY assets/ ./assets/
COPY pubs-src/ ./pubs-src/
COPY themes/jsonresume-theme-even/ ./themes/jsonresume-theme-even/
COPY docker/entrypoint.sh /usr/local/bin/vita-pipeline

RUN pip3 install --no-cache-dir --break-system-packages -r requirements-docker.txt \
  && npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
  && npm cache clean --force \
  && rm -rf themes/jsonresume-theme-even themes/jsonresume.org \
  && rm -f package.json package-lock.json requirements-docker.txt \
  && chmod +x /opt/vita-toolkit/scripts/run_pipeline.sh /usr/local/bin/vita-pipeline

ARG PREWARM_CACHE=0
RUN if [ "$PREWARM_CACHE" = "1" ]; then \
      cd pubs-src && tectonic prime-tectonic.tex && \
      (echo '#import "@preview/brilliant-cv:3.1.2"'; \
       echo '#import "@preview/fontawesome:0.6.0"') | typst compile - prime-typst.pdf && \
      rm -f *.pdf; \
    fi

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/vita-pipeline"]
CMD ["--help"]
