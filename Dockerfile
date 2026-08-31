# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
FROM node:24.14.0-slim@sha256:e8e2e91b1378f83c5b2dd15f0247f34110e2fe895f6ca7719dbb780f929368eb AS node

FROM texlive/texlive:latest-basic@sha256:4da564c0fb1f36f6e72767d4d50b985d8586b2e959399e3b8a08ccb6550c661e

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG TL_REPO=http://mirror.ctan.org/systems/texlive/tlnet/

# --------------------------------------------------
# Node.js
# --------------------------------------------------
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# --------------------------------------------------
# tlmgr packages
# --------------------------------------------------
RUN --mount=type=cache,target=/var/cache/tlmgr,sharing=locked \
    set -eux; \
    tlmgr option repository "${TL_REPO}"; \
    tlmgr option docfiles 0; \
    tlmgr option srcfiles 0; \
    tlmgr option autobackup 0; \
    tlmgr install \
      collection-latexrecommended \
      collection-latexextra \
      collection-fontsrecommended \
      collection-bibtexextra \
      collection-luatex \
      collection-langjapanese \
      latexmk \
      biber; \
    tlmgr path add

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
