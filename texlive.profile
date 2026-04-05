# TeX Live installation profile
# Reference year: 2025
# When building with a different TL_YEAR, Dockerfile.base uses sed to substitute paths.
# Do not change this file manually for year updates; update TL_YEAR in Dockerfile.base instead.
# The test-next-year workflow also updates this file when creating a year-update PR.
selected_scheme scheme-basic
TEXDIR /usr/local/texlive/2025
TEXMFCONFIG ~/.texlive2025/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL /usr/local/texlive/texmf-local
TEXMFSYSCONFIG /usr/local/texlive/2025/texmf-config
TEXMFSYSVAR /usr/local/texlive/2025/texmf-var
TEXMFVAR ~/.texlive2025/texmf-var
binary_x86_64-linux 1
instopt_adjustpath 0
instopt_adjustrepo 1
instopt_letter 0
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 0
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_post_code 1
