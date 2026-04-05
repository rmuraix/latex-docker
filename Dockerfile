# syntax=docker/dockerfile:1
#
# Multi-stage build:
#   latex-base — Debian slim + TeX Live (via install-tl from historic tlnet-final)
#   latex      — latex-base + Node.js runtime
#
# Both stages are pushed to GHCR by the build workflow using --target.
# The GHA cache preserves TeX Live installation layers between runs.
#
# Digest pins are managed by Renovate (monthly, auto-merge).
# TL_YEAR updates are handled by .github/workflows/test-next-year.yaml (manual merge).

ARG DEBIAN_VERSION=12

# ── Node.js source (binary copy only) ─────────────────────────────────────
# renovate: datasource=docker depName=node versioning=docker
FROM node:24.14.0-slim@sha256:d8e448a56fc63242f70026718378bd4b00f8c82e78d20eefb199224a4d8e33d8 AS node

# ── latex-base ─────────────────────────────────────────────────────────────
# renovate: datasource=docker depName=debian versioning=docker
FROM debian:${DEBIAN_VERSION}-slim@sha256:f06537653ac770703bc45b4b113475bd402f451e85223f0f2837acbf89ab020a AS latex-base

ARG TL_YEAR=2025

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# --------------------------------------------------
# OS dependencies for install-tl
# --------------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      fontconfig \
      perl \
      wget \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# TeX Live installation profile
# --------------------------------------------------
# Copy the reference profile (year 2025) and substitute TL_YEAR at build time.
# This allows next-year test builds to pass --build-arg TL_YEAR=2026 without
# modifying the checked-in profile.
COPY texlive.profile /tmp/texlive.profile.orig
RUN sed \
      -e "s|/texlive/2025|/texlive/${TL_YEAR}|g" \
      -e "s|texlive2025|texlive${TL_YEAR}|g" \
      /tmp/texlive.profile.orig > /tmp/texlive.profile \
 && rm /tmp/texlive.profile.orig

# --------------------------------------------------
# install-tl — downloaded from the same historic repository
# NOTE: URL is constructed in the shell; Docker does not expand ARGs
# inside other ARG default values.
# --------------------------------------------------
RUN --mount=type=cache,target=/var/cache/install-tl,sharing=locked \
    set -euxo pipefail; \
    TL_REPO="https://tug.org/historic/systems/texlive/${TL_YEAR}/tlnet-final"; \
    INSTALLER=$(mktemp -d); \
    wget -qO- "${TL_REPO}/install-tl-unx.tar.gz" | tar -xz -C "${INSTALLER}"; \
    "${INSTALLER}"/install-tl-*/install-tl \
        --repository="${TL_REPO}" \
        --profile=/tmp/texlive.profile \
        --no-interaction; \
    rm -rf "${INSTALLER}" /tmp/texlive.profile

# --------------------------------------------------
# PATH: explicit year + arch directory (no wildcard symlinks)
# ENV CAN reference ARG values declared in the same stage.
# --------------------------------------------------
ENV PATH="/usr/local/texlive/${TL_YEAR}/bin/x86_64-linux:${PATH}"

# --------------------------------------------------
# Additional collections and tools (via tlmgr)
# Repository pinned to the same historic snapshot
# --------------------------------------------------
RUN set -eux; \
    TL_REPO="https://tug.org/historic/systems/texlive/${TL_YEAR}/tlnet-final"; \
    tlmgr option repository "${TL_REPO}"; \
    tlmgr option -- autobackup 0; \
    tlmgr option -- docfiles 0; \
    tlmgr option -- srcfiles 0; \
    tlmgr install \
      collection-latexrecommended \
      collection-latexextra \
      collection-fontsrecommended \
      collection-bibtexextra \
      collection-luatex \
      collection-langjapanese \
      latexmk \
      biber; \
    rm -rf /usr/local/texlive/${TL_YEAR}/tlpkg/backups; \
    mktexlsr

# ── latex ──────────────────────────────────────────────────────────────────
# Adds Node.js to latex-base. Does NOT run tlmgr.
FROM latex-base AS latex

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# --------------------------------------------------
# Node.js
# --------------------------------------------------
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# --------------------------------------------------
# Workspace
# --------------------------------------------------
RUN set -eux; \
    useradd --create-home --shell /bin/bash dev; \
    mkdir -p /work; \
    chown dev: /work

ENV HOME=/home/dev \
    XDG_CACHE_HOME=${HOME}/.cache \
    NPM_CONFIG_PREFIX=${HOME}/.npm-global \
    PATH="${HOME}/.npm-global/bin:${PATH}"

WORKDIR /work
USER dev
