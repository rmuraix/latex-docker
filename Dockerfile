# syntax=docker/dockerfile:1
FROM node:24.14.0-slim@sha256:e8e2e91b1378f83c5b2dd15f0247f34110e2fe895f6ca7719dbb780f929368eb AS node

FROM texlive/texlive:latest-basic@sha256:c561ec28af7b73e68d26e84839f3f1fb642801295c8e3c7957dccf841195e7de

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
    if ! getent group 1000 >/dev/null 2>&1; then \
      groupadd --gid 1000 dev; \
    fi; \
    if ! getent passwd 1000 >/dev/null 2>&1; then \
      useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash dev; \
    else \
      useradd --gid 1000 --create-home --shell /bin/bash dev; \
    fi; \
    mkdir -p /work; \
    chown dev: /work

ENV HOME=/home/dev \
    XDG_CACHE_HOME=${HOME}/.cache \
    NPM_CONFIG_PREFIX=${HOME}/.npm-global \
    PATH="${HOME}/.npm-global/bin:${PATH}"

WORKDIR /work
USER dev
