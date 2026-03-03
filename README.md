# Docker Image for LaTeX

![Licence](https://img.shields.io/github/license/rmuraix/latex-docker)
[![Build and publish](https://github.com/rmuraix/latex-docker/actions/workflows/build.yaml/badge.svg)](https://github.com/rmuraix/latex-docker/actions/workflows/build.yaml)

## About

Debian-based image with TeX Live and Node.js preinstalled for building LaTeX documents, including Japanese support.

## Usage

### Image Tags

- `latest`: latest build from the default branch.
- `vX.Y.Z`: SemVer tags assigned according to changes.
- `YYYY-MM-DD`: monthly snapshot tag. May include changes beyond dependency digest updates.

### Build LaTeX Documents

```bash
# pdfLaTeX
docker run --rm -v $(pwd):/work ghcr.io/rmuraix/latex:latest latexmk -pdf main.tex
# LuaLaTeX
docker run --rm -v $(pwd):/work ghcr.io/rmuraix/latex:latest latexmk -lualatex main.tex
```

### Dev Container with VS Code

I have published a Devcontainer template using this Docker image at [rmuraix/template-latex](https://github.com/rmuraix/template-lalex).

### Interactive Shell

```bash
docker run --rm -it -v $(pwd):/work ghcr.io/rmuraix/latex:latest /bin/bash
```

### Build the Docker Image

```bash
git clone https://github.com/rmuraix/latex-docker.git
cd latex-docker
docker build -t latex:latest .
```

## Contributing

Your contribution is always welcome. Please read [Contributing Guide](https://github.com/rmuraix/.github/blob/main/.github/CONTRIBUTING.md).
