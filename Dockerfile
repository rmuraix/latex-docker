# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

ARG TL_REPO=http://mirror.ctan.org/systems/texlive/tlnet/
ARG NODE_VERSION=24.13.1

# TeX Live
ENV TL_TEXDIR=/usr/local/texlive/current
ENV TL_BIN=${TL_TEXDIR}/bin/x86_64-linux
ENV PATH="${TL_BIN}:/usr/local/node/bin:$PATH"

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
    ca-certificates \
    curl \
    fontconfig \
    make \
    perl \
    python3 \
    tar \
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
# TeX Live base install
# --------------------------------------------------
RUN --mount=type=cache,target=/var/cache/texlive-installer,sharing=locked \
    set -eux; \
    mkdir -p /tmp/install-tl-unx; \
    curl -L "${TL_REPO}/install-tl-unx.tar.gz" \
      -o /var/cache/texlive-installer/install-tl-unx.tar.gz; \
    tar -xzf /var/cache/texlive-installer/install-tl-unx.tar.gz \
      -C /tmp/install-tl-unx --strip-components=1; \
    printf '%s\n' \
      'selected_scheme scheme-basic' \
      'tlpdbopt_install_docfiles 0' \
      'tlpdbopt_install_srcfiles 0' \
      > /tmp/install-tl-unx/texlive.profile; \
    /tmp/install-tl-unx/install-tl \
      --repository "${TL_REPO}" \
      --texdir "${TL_TEXDIR}" \
      -profile /tmp/install-tl-unx/texlive.profile; \
    rm -rf /tmp/install-tl-unx

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
# Align ubuntu UID/GID with host if requested
# --------------------------------------------------
RUN set -eux; \
    if [ "$(id -u ubuntu)" != "${USER_UID}" ]; then \
      usermod -u "${USER_UID}" ubuntu; \
    fi; \
    if [ "$(id -g ubuntu)" != "${USER_GID}" ]; then \
      groupmod -g "${USER_GID}" ubuntu; \
    fi; \
    chown -R "${USER_UID}:${USER_GID}" /home/ubuntu

# --------------------------------------------------
# Workspace
# --------------------------------------------------
WORKDIR /work
USER ubuntu
