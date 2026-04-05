# Operation Guide

## Architecture

```
Dockerfile.base ──build──▶ ghcr.io/{owner}/latex-base:2025
                                      │ digest pinned
Dockerfile      ──build──▶ ghcr.io/{owner}/latex:latest
```

### latex-base

| Property | Value |
|---|---|
| Base OS | `debian:12-slim` (digest pinned) |
| TeX Live year | 2025 (fixed via `TL_YEAR` build arg) |
| TeX Live source | `https://ftp.tug.org/historic/systems/texlive/2025/tlnet-final` |
| install-tl source | Same historic URL |
| tlmgr repository | Same historic URL |
| PATH | `/usr/local/texlive/2025/bin/x86_64-linux` (explicit, no symlinks) |

### latex

| Property | Value |
|---|---|
| Base | `ghcr.io/{owner}/latex-base` (digest pinned) |
| Added | Node.js binary + npm (from `node:24.x-slim`) |
| tlmgr usage | None — all TeX packages come from `latex-base` |

### Image tags

| Image | Tag pattern | Meaning |
|---|---|---|
| `latex-base` | `2025` | Latest build for TeX Live 2025 |
| `latex-base` | `2025-YYYYMMDD` | Dated snapshot |
| `latex` | `latest` | Latest build on main |
| `latex` | `vX.Y.Z` | Semver release |
| `latex` | `YYYY-MM-DD` | Monthly Renovate snapshot (Asia/Tokyo date) |

---

## Normal Operations (fully automated)

Renovate opens monthly PRs to update image digests (OS, Node.js, latex-base).
These are auto-merged when CI passes.

| Renovate group | Files touched | Auto-merge |
|---|---|---|
| `monthly updates` | `Dockerfile` (node, latex-base digests) | Yes |
| `monthly base updates` | `Dockerfile.base` (debian digest) | Yes |

After a `monthly-base` PR merges, `monthly.yaml` rebuilds and repushes `latex-base`.
After a `monthly` PR merges, `monthly.yaml` rebuilds `latex` and adds a `YYYY-MM-DD` tag.

---

## TeX Live Year Update (semi-automated)

The `test-next-year.yaml` workflow runs on the 1st of each month and:

1. Checks whether `https://ftp.tug.org/historic/systems/texlive/{NEXT_YEAR}/tlnet-final/` is available.
2. If yes, builds `Dockerfile.base` with `TL_YEAR={NEXT_YEAR}`.
3. Runs the full test suite (pdflatex, lualatex+Japanese, biber).
4. If all tests pass, opens a PR updating `TL_YEAR` in `Dockerfile.base` and year paths in `texlive.profile`.

**The PR is NOT auto-merged.**

### Reviewing a year-update PR

Before merging:

- [ ] Check [TeX Live release notes](https://tug.org/texlive/) for breaking changes
- [ ] Verify the historic URL is stable and complete
- [ ] Review CI results in the PR
- [ ] Optionally test locally (see below)

After merging:

1. `build-base.yaml` runs automatically and pushes `latex-base:{NEW_YEAR}` to GHCR.
2. Renovate detects the new `latex-base` digest and opens a `monthly updates` PR for `Dockerfile`.
3. That PR auto-merges and `build.yaml` rebuilds `latex:latest`.

---

## First-Time Setup

When deploying this repository from scratch (e.g., in a fork):

### 1. Obtain OS and Node.js digests

```sh
# debian:12-slim (amd64)
docker pull --platform linux/amd64 debian:12-slim
docker inspect --format='{{index .RepoDigests 0}}' debian:12-slim
# → debian@sha256:...

# node:24.14.0-slim (amd64) — use the version pinned in Dockerfile
docker pull --platform linux/amd64 node:24.14.0-slim
docker inspect --format='{{index .RepoDigests 0}}' node:24.14.0-slim
# → node@sha256:...
```

Update:
- `Dockerfile.base`: replace the `debian:12-slim@sha256:...` digest
- `Dockerfile`: replace the `node:...-slim@sha256:...` digest (already pinned from upstream)

### 2. Build and push latex-base

Trigger `build-base.yaml` via `workflow_dispatch` or push a change to `Dockerfile.base`.
After the workflow succeeds, note the pushed digest:

```sh
docker pull ghcr.io/{owner}/latex-base:2025
docker inspect --format='{{index .RepoDigests 0}}' ghcr.io/{owner}/latex-base:2025
# → ghcr.io/{owner}/latex-base@sha256:...
```

### 3. Pin latex-base digest in Dockerfile

Replace the placeholder `sha256:TOFILL_AFTER_FIRST_LATEX_BASE_BUILD` in `Dockerfile` with the real digest.
Commit and push — `build.yaml` will build and publish `latex:latest`.

Subsequent digest updates are handled by Renovate automatically.

---

## Manual Rebuild

To force a rebuild without code changes:

```
# Rebuild latex-base
gh workflow run build-base.yaml

# Rebuild latex
gh workflow run build.yaml
```

Or trigger `repository_dispatch` from `build-base.yaml` (see `on.repository_dispatch.types: [latex-base-updated]` in `build.yaml`).

---

## Local Testing

```sh
# Build and test latex-base locally
docker build -f Dockerfile.base -t latex-base:local .

docker run --rm -v $(pwd)/tests:/work latex-base:local \
  latexmk -pdf -interaction=nonstopmode -halt-on-error \
    -output-directory=/tmp pdflatex.tex

docker run --rm -v $(pwd)/tests:/work latex-base:local \
  latexmk -lualatex -interaction=nonstopmode -halt-on-error \
    -output-directory=/tmp lualatex.tex

docker run --rm -v $(pwd)/tests:/work latex-base:local \
  sh -c "cd /work && latexmk -lualatex -interaction=nonstopmode -halt-on-error \
    -output-directory=/tmp biber.tex"

# Test next TeX Live year locally
docker build -f Dockerfile.base --build-arg TL_YEAR=2026 -t latex-base:2026-test .
```

---

## Troubleshooting

### tlnet-final URL returns 404

The historic archive is published by TUG after the freeze of each year's release (typically May–June).
If the check step in `test-next-year.yaml` reports a non-200 status, simply wait; the workflow runs monthly and will retry automatically.

### Build fails with "package not found"

Historic tlnet-final archives are complete snapshots. If a package is missing, it likely wasn't in TeX Live at that year. Consider whether the package was introduced in a later year or has been renamed.

### Renovate doesn't detect the latex-base digest update

Renovate needs GHCR access to check digests. Ensure the Renovate app has been granted `read:packages` permissions on the repository, or that a `RENOVATE_TOKEN` secret with package read access is configured.

### The year-update PR was created but the next build is broken

Do not merge the PR. Close it. The failing CI in the PR will indicate what needs to be investigated (e.g., a collection was renamed, a package was split). Fix `Dockerfile.base` or `texlive.profile` manually and push to the `update/texlive-{YEAR}` branch to update the PR.
