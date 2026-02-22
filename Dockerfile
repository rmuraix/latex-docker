# syntax=docker/dockerfile:1
FROM node:24.13.1 AS node

FROM texlive/texlive:latest-basic@sha256:d016e51c39c7e8042081adf9edf7f9c6fd7229d6010ff0f32396f9b9ba83ec1b

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG TL_REPO=http://mirror.ctan.org/systems/texlive/tlnet/

# --------------------------------------------------
# Node.js
# --------------------------------------------------
COPY --from=node /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

# --------------------------------------------------
# tlmgr packages
# --------------------------------------------------
RUN --mount=type=cache,target=/var/cache/tlmgr,sharing=locked \
    set -eux; \
    tlmgr option repository "${TL_REPO}"; \
    tlmgr update --self; \
    tlmgr install \
      collection-latexrecommended \
      collection-latexextra \
      collection-fontsrecommended \
      collection-bibtexextra \
      collection-luatex \
      collection-langjapanese \
      latexmk \
      biber

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
    XDG_CACHE_HOME=/home/dev/.cache

WORKDIR /work
USER dev
