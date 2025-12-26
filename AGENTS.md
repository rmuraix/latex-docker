# Repository Guidelines

## Project Structure & Module Organization
- `Dockerfile` is the primary source; it defines the Ubuntu-based image with TeX Live and Node.js.
- `README.md` contains a brief overview and links to the shared contribution guide.
- The container work directory is `/work` (set by `WORKDIR`), intended as the mount point for your LaTeX project.

## Build, Test, and Development Commands
- `docker build -t latex-docker .` builds the image locally.
- `docker run --rm -v "$PWD":/work latex-docker latexmk -pdf main.tex` compiles a LaTeX file in the current directory.
- `docker run --rm -it latex-docker bash` opens a shell for interactive inspection.

## Coding Style & Naming Conventions
- Keep Dockerfile instructions grouped by purpose (OS deps, Node.js, TeX Live, packages, workspace) with clear section headers.
- Prefer explicit `ARG`/`ENV` in uppercase (e.g., `TL_REPO`, `NODE_VERSION`) and pin versions where practical.
- Use `set -eux` in multi-command `RUN` steps and favor `--no-install-recommends` for apt installs.

## Testing Guidelines
- No automated tests are defined in this repository.
- Validation is done by building the Docker image and running a sample LaTeX compile (see commands above).

## Commit & Pull Request Guidelines
- The Git history currently includes only an initial commit, so no established commit message convention exists. Use concise, imperative messages (e.g., "Update TeX Live packages").
- PRs should include a short description of the change and any notable build-time or runtime impact.
- Follow the shared contribution guide: https://github.com/rmuraix/.github/blob/main/.github/CONTRIBUTING.md

## Configuration Tips
- `TL_REPO` controls the TeX Live mirror; adjust it if you need a specific CTAN mirror.
- `NODE_VERSION` is pinned; update it alongside any related documentation or build notes.
