# syntax=docker/dockerfile:1
#
# latex: distribution image built on top of latex-base.
# Adds Node.js runtime. Does NOT run tlmgr.
#
# Base image digests are managed by Renovate (monthly, auto-merge).
# To update the latex-base digest after a new latex-base build:
#   docker pull ghcr.io/rmuraix/latex-base:2025
# and replace the sha256 below with the output of `docker inspect --format='{{index .RepoDigests 0}}'`.

# renovate: datasource=docker depName=node versioning=docker
FROM node:24.14.0-slim@sha256:e8e2e91b1378f83c5b2dd15f0247f34110e2fe895f6ca7719dbb780f929368eb AS node

# renovate: datasource=docker depName=ghcr.io/rmuraix/latex-base versioning=docker
FROM ghcr.io/rmuraix/latex-base@sha256:TOFILL_AFTER_FIRST_LATEX_BASE_BUILD

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
