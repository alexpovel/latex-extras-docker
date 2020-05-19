# texlive.profile written on Mon May 18 12:21:10 2020 UTC
# It will NOT be updated and reflects only the
# installation profile at installation time.
selected_scheme scheme-custom

# File has to have LF line endings to work with `install-tl` Perl script!

# Directories copied from default, with '2020' replaced by 'current'; probably doesn't
# matter, but 2020 will eventually be wrong.
TEXDIR /usr/local/texlive/current
TEXMFCONFIG ~/.texlivecurrent/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL /usr/local/texlive/texmf-local
TEXMFSYSCONFIG /usr/local/texlive/current/texmf-config
TEXMFSYSVAR /usr/local/texlive/current/texmf-var
TEXMFVAR ~/.texlivecurrent/texmf-var
#
binary_x86_64-linux 1
# Collections of packages; for their contents, see
# http://mirror.ctan.org/systems/texlive/tlnet/tlpkg/texlive.tlpdb
# and search for 'name collection-<name>', e.g. 'name collection-basic'.
# At the time of writing, the following encompasses all available collections.
# Only the core ones with very few supported languages are enabled. For example,
# just including 'collection-langjapanese' requires 800MB of space.
collection-basic 1
collection-bibtexextra 1
collection-binextra 1
collection-fontsextra 1
collection-fontsrecommended 1
collection-fontutils 1
collection-formatsextra 1
collection-langenglish 1
collection-langeuropean 1
collection-langgerman 1
collection-latex 1
collection-latexextra 1
collection-latexrecommended 1
collection-luatex 1
collection-mathscience 1
collection-pictures 1
collection-plaingeneric 1
collection-publishers 1
collection-xetex 1
# Enable the following disabled ones as needed
collection-context 0
collection-games 0
collection-humanities 0
collection-langarabic 0
collection-langchinese 0
collection-langcjk 0
collection-langcyrillic 0
collection-langczechslovak 0
collection-langfrench 0
collection-langgreek 0
collection-langitalian 0
collection-langjapanese 0
collection-langkorean 0
collection-langother 0
collection-langpolish 0
collection-langportuguese 0
collection-langspanish 0
collection-metapost 0
collection-music 0
collection-pstricks 0
collection-texworks 0
collection-wintools 0
collection-xetex 0
# Options for TeXLive installation
# Automatically adjust $PATH environment variable
instopt_adjustpath 1
# Adjust remote CTAN repository
instopt_adjustrepo 1
# A4 default, not letter format
instopt_letter 0
# No portable installation required
instopt_portable 0
# Required for --shell-escape lualatex option
instopt_write18_restricted 1
# Autobackup just fills cache, skip; see
# https://tex.stackexchange.com/a/398831/120853
tlpdbopt_autobackup 0
tlpdbopt_backupdir tlpkg/backups
# Create font format files, otherwise they have to be created on the fly each time.
tlpdbopt_create_formats 1
# None of the following is required; especially not documentation and source files,
# which fill multiple GBs
tlpdbopt_desktop_integration 0
tlpdbopt_file_assocs 0
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
#
tlpdbopt_post_code 1
tlpdbopt_sys_bin /usr/local/bin
tlpdbopt_sys_info /usr/local/share/info
tlpdbopt_sys_man /usr/local/share/man
tlpdbopt_w32_multi_user 1