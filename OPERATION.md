# Operation Guide

## Architecture

```
Dockerfile (multi-stage)
  ├─ [stage: latex-base] ──▶ ghcr.io/{owner}/latex-base:2025
  └─ [stage: latex]      ──▶ ghcr.io/{owner}/latex:latest

GHA cache preserves the TeX Live installation layer between runs.
```

### latex-base stage

| Property | Value |
|---|---|
| Base OS | `debian:12-slim` (digest pinned, Renovate-managed) |
| TeX Live year | 2025 (fixed via `TL_YEAR` build arg) |
| TeX Live source | `https://tug.org/historic/systems/texlive/2025/tlnet-final` |
| install-tl source | Same historic URL |
| tlmgr repository | Same historic URL |
| PATH | `/usr/local/texlive/2025/bin/x86_64-linux` (explicit, no symlinks) |

### latex stage

| Property | Value |
|---|---|
| Base | `latex-base` (local stage reference, not pulled from registry) |
| Added | Node.js binary + npm (from `node:24.x-slim`, digest pinned) |
| tlmgr usage | None — all TeX packages come from `latex-base` stage |

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

Renovate opens monthly PRs to update `debian` and `node` image digests in `Dockerfile`.
These are auto-merged when CI passes.

| Renovate group | Files touched | Auto-merge |
|---|---|---|
| `monthly updates` | `Dockerfile` (debian + node digests) | Yes |

After a monthly PR merges, `monthly.yaml` rebuilds and pushes both `latex-base` and `latex`
with a `YYYY-MM-DD` date tag.

---

## TeX Live Year Update (semi-automated)

The `test-next-year.yaml` workflow runs on the 1st of each month and:

1. Checks whether `https://tug.org/historic/systems/texlive/{NEXT_YEAR}/tlnet-final/` is available.
2. If yes, builds the `latex-base` stage with `TL_YEAR={NEXT_YEAR}`.
3. Runs the full test suite (pdflatex, lualatex+Japanese, biber).
4. If all tests pass, opens a PR updating `TL_YEAR` in `Dockerfile` and year paths in `texlive.profile`.

**The PR is NOT auto-merged.**

### Reviewing a year-update PR

Before merging:

- [ ] Check [TeX Live release notes](https://tug.org/texlive/) for breaking changes
- [ ] Verify the historic URL is stable and complete
- [ ] Review CI results in the PR
- [ ] Optionally test locally (see below)

After merging:

1. `build.yaml` runs automatically, pushes `latex-base:{NEW_YEAR}` and `latex:latest` to GHCR.

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

Update the two digest values in `Dockerfile` and push to main.
`build.yaml` will build and publish both images automatically.

---

## Manual Rebuild

To force a rebuild without code changes:

```sh
gh workflow run build.yaml
```

---

## Local Testing

```sh
# Build and test the latex-base stage
docker build --target latex-base -t latex-base:local .

docker run --rm -v $(pwd)/tests:/work latex-base:local \
  latexmk -pdf -interaction=nonstopmode -halt-on-error \
    -output-directory=/tmp pdflatex.tex

docker run --rm -v $(pwd)/tests:/work latex-base:local \
  latexmk -lualatex -interaction=nonstopmode -halt-on-error \
    -output-directory=/tmp lualatex.tex

docker run --rm -v $(pwd)/tests:/work latex-base:local \
  sh -c "cd /work && latexmk -lualatex -interaction=nonstopmode -halt-on-error \
    -output-directory=/tmp biber.tex"

# Build the final latex image
docker build -t latex:local .

# Test next TeX Live year locally
docker build --target latex-base --build-arg TL_YEAR=2026 -t latex-base:2026-test .
```

---

## Troubleshooting

### tlnet-final URL returns 404

The historic archive is published by TUG after the freeze of each year's release (typically May–June).
If the check step in `test-next-year.yaml` reports a non-200 status, simply wait; the workflow runs monthly and will retry automatically.

### Build fails with "package not found"

Historic tlnet-final archives are complete snapshots. If a package is missing, it likely wasn't in TeX Live at that year. Consider whether the package was introduced in a later year or has been renamed.

### The year-update PR was created but the next build is broken

Do not merge the PR. Close it. The failing CI in the PR will indicate what needs to be investigated (e.g., a collection was renamed, a package was split). Fix `Dockerfile` or `texlive.profile` manually and push to the `update/texlive-{YEAR}` branch to update the PR.
