# Docker Image for LaTeX

![Licence](https://img.shields.io/github/license/rmuraix/latex-docker)
[![Build and publish](https://github.com/rmuraix/latex-docker/actions/workflows/build.yaml/badge.svg)](https://github.com/rmuraix/latex-docker/actions/workflows/build.yaml)

## About

Ubuntu-based image with TeX Live and Node.js preinstalled for building LaTeX documents, including Japanese support.

## Usage

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
