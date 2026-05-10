# CLAUDE.md

## Project Overview

This repository produces a Docker image for compiling LaTeX documents. The image bundles TeX Live and Node.js on a Debian base and is published to GitHub Container Registry (GHCR) as `ghcr.io/rmuraix/latex`.

Key capabilities of the image:
- pdfLaTeX and LuaLaTeX compilation via `latexmk`
- Full Japanese typesetting support (`collection-langjapanese`, `luatexja`)
- Node.js available as a non-root user for tooling (e.g., linters, preprocessors)
- Ready for use as a VS Code Dev Container

---

## Repository Structure

```
.
├── Dockerfile                  # Single source of truth for the image
├── tests/
│   ├── pdflatex.tex            # CI smoke test for pdfLaTeX
│   └── lualatex.tex            # CI smoke test for LuaLaTeX (includes Japanese)
├── .devcontainer/
│   └── devcontainer.json       # VS Code Dev Container config (LaTeX Workshop)
├── .github/
│   ├── renovate.json           # Automated dependency update rules
│   └── workflows/
│       ├── build.yaml          # Build, test, and publish on push/PR
│       ├── monthly.yaml        # Add YYYY-MM-DD tag on merged monthly PRs
│       └── release.yaml        # Create GitHub Release on vX.Y.Z tags
├── .gitignore                  # Comprehensive LaTeX build artifact exclusions
├── AGENTS.md                   # Guidelines for AI coding agents
└── README.md                   # User-facing documentation
```

---

## Dockerfile Conventions

The Dockerfile uses a **two-stage build** pattern:
1. **`node` stage** — pulls the pinned Node.js slim image and acts as a source for binaries only.
2. **`texlive/texlive` stage** — the actual runtime image; Node.js binaries are `COPY --from=node`.

### Key rules when editing the Dockerfile

- **Pin base image digests** (both `node` and `texlive/texlive`) using `@sha256:...`. Renovate manages these digests automatically; do not remove them.
- Group `RUN` instructions by logical purpose with comment headers (e.g., `# Node.js`, `# tlmgr packages`, `# Workspace`).
- Use `set -eux` in every multi-command `RUN` step.
- Use `--mount=type=cache` for `tlmgr` to speed up repeated local builds.
- The non-root user inside the container is `dev`; `WORKDIR` is `/work`.
- `DEBIAN_FRONTEND=noninteractive` and `LANG=C.UTF-8` must stay set.
- `ARG` and `ENV` names use UPPER_SNAKE_CASE.
- `TL_REPO` controls the CTAN mirror; keep it as `ARG` so it can be overridden at build time.

### TeX Live packages installed

| Collection / Package | Purpose |
|---|---|
| `collection-latexrecommended` | Core LaTeX |
| `collection-latexextra` | Extended packages |
| `collection-fontsrecommended` | Common fonts |
| `collection-bibtexextra` | BibTeX/BibLaTeX |
| `collection-luatex` | LuaLaTeX engine |
| `collection-langjapanese` | Japanese typesetting |
| `latexmk` | Build automation |
| `biber` | BibLaTeX backend |

When adding new TeX packages, append them to the existing `tlmgr install` block — do not create a new `RUN` layer.

---

## Development Workflow

### Local image build

```bash
docker build -t latex-docker .
```

### Run the CI tests locally

```bash
# pdfLaTeX test
docker run --rm -v "$PWD/tests":/work latex-docker \
  latexmk -pdf -interaction=nonstopmode -halt-on-error \
  -output-directory=/tmp pdflatex.tex

# LuaLaTeX test
docker run --rm -v "$PWD/tests":/work latex-docker \
  latexmk -lualatex -interaction=nonstopmode -halt-on-error \
  -output-directory=/tmp lualatex.tex

# npm availability test (runs as non-root)
docker run --rm latex-docker npm --version
```

### Interactive shell

```bash
docker run --rm -it -v "$PWD":/work latex-docker /bin/bash
```

---

## CI/CD Pipelines

### `build.yaml` — Build, test, publish

**Triggers:** push to `main`, push of `v*` tags, PRs targeting `main` — only when `Dockerfile`, `build.yaml`, or `tests/**` change; also `workflow_dispatch`.

**Steps:**
1. Build image with Docker Buildx (GitHub Actions cache).
2. On push to `main` or a `v*` tag: push `latest` (and the tag ref) to GHCR.
3. Run three tests: pdfLaTeX compile, LuaLaTeX compile, `npm --version`.

Image is published to: `ghcr.io/<owner>/latex` (owner derived from `github.repository_owner`).

### `monthly.yaml` — Date-tagged snapshots

**Triggers:** PR closed (merged) on the default branch, PR has label `monthly`, PR author ID matches the repo owner.

Builds and pushes a `YYYY-MM-DD` tag (Asia/Tokyo timezone).

### `release.yaml` — GitHub Releases

**Triggers:** push of `v*` tags.

Creates a GitHub Release with auto-generated release notes.

---

## Dependency Updates (Renovate)

Renovate is configured to:
- Pin Docker image digests (`docker:pinDigests`).
- Group `texlive/texlive` and `node` digest/minor/patch updates into a single monthly PR (scheduled first day of each month).
- Auto-merge monthly updates and label them `monthly` (which triggers `monthly.yaml` after merge).

When Renovate opens a grouped PR, it will be auto-merged by CI if tests pass. Do not manually edit the digest pins; Renovate owns them.

---

## Image Tags

| Tag | Description |
|---|---|
| `latest` | Latest build from `main` |
| `vX.Y.Z` | SemVer release (created by pushing a git tag) |
| `YYYY-MM-DD` | Monthly snapshot (created after merging a `monthly`-labelled PR) |

---

## Tests

Tests live in `tests/`. Each `.tex` file is a minimal but non-trivial document that exercises real packages:

- `pdflatex.tex`: Uses `amsmath`, `geometry`, `hyperref`, `graphicx`, `booktabs`, `xcolor`.
- `lualatex.tex`: Uses `luatexja`, `fontspec`, `amsmath`, `geometry`, `hyperref`, plus Japanese Unicode text.

If you add new TeX collections to the Dockerfile, add a corresponding test that actually exercises the new functionality.

---

## Dev Container

`.devcontainer/devcontainer.json` configures VS Code to:
- Build from the repository `Dockerfile`.
- Install the **LaTeX Workshop** extension (`James-Yu.latex-workshop`).
- Provide two build recipes: `pdfLaTeX` and `LuaLaTeX`, both using `latexmk` with `-interaction=nonstopmode -file-line-error`.
- Disable auto-build on save (`latex-workshop.latex.autoBuild.run: "never"`).

The remote user in the Dev Container is `ubuntu` (provided by the `common-utils` devcontainer feature), distinct from the image's internal `dev` user.

---

## Commit Message Convention

Use short, imperative messages. Follow the patterns visible in the git history:

- `fix: <description>` — bug fixes
- `chore: <description>` — maintenance, dependency bumps
- `chore(deps): <description>` — dependency updates (Renovate format)
- `docs: <description>` — documentation changes
- `test: <description>` — test additions/changes
- No type prefix needed for feature work; keep the message concise (e.g., `Simplify Dockerfile user creation`)

Do not include issue numbers in the commit subject; they belong in the PR body.

---

## What Not to Do

- Do not add `apt-get install` calls unless a required tool is unavailable via `tlmgr` or the Node.js binary copy. Keep the image lean.
- Do not remove `--mount=type=cache` from the `tlmgr` `RUN` step.
- Do not unpin base image digests.
- Do not add a second `tlmgr install` `RUN` step; extend the existing one.
- Do not commit LaTeX build artifacts (`.aux`, `.log`, `.pdf`, etc.) — they are covered by `.gitignore`.
- Do not push directly to `main`; open a PR.
