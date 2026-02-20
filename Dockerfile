# syntax=docker/dockerfile:1
FROM texlive/texlive:latest-basic@sha256:d016e51c39c7e8042081adf9edf7f9c6fd7229d6010ff0f32396f9b9ba83ec1b

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG TL_REPO=http://mirror.ctan.org/systems/texlive/tlnet/
ARG NODE_VERSION=24.13.1

# Node.js
ENV PATH="/usr/local/node/bin:$PATH"

# User
ARG USER_UID=1000
ARG USER_GID=1000

# --------------------------------------------------
# OS dependencies
# --------------------------------------------------
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
 && apt-get install -y --no-install-recommends \
    xz-utils \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Node.js
# --------------------------------------------------
RUN --mount=type=cache,target=/var/cache/node,sharing=locked \
    set -eux; \
    curl -L "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
      -o /var/cache/node/node.tar.xz; \
    tar -xJf /var/cache/node/node.tar.xz -C /usr/local; \
    ln -s /usr/local/node-v${NODE_VERSION}-linux-x64 /usr/local/node

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
# Create ubuntu user
# --------------------------------------------------
RUN set -eux; \
    groupadd -g "${USER_GID}" ubuntu; \
    useradd -u "${USER_UID}" -g "${USER_GID}" -m -s /bin/bash ubuntu

# --------------------------------------------------
# Workspace
# --------------------------------------------------
WORKDIR /work
USER ubuntu
