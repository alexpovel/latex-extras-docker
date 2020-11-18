# ARGs before the first FROM are global and usable in all stages
ARG BASE_OS=debian
ARG OS_VERSION=testing

# Image with layers as used by all succeeding steps
FROM ${BASE_OS}:${OS_VERSION} as BASE

# Use `apt-get` over just `apt`, see https://askubuntu.com/a/990838/978477.
# Also run `apt-get update` on every `RUN`, see:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        # wget for `install-tl` script to download TeXLive, and other downloads.
        wget \
        # In a similar vein, `curl` is required by various tools, or is just very
        # nice to have for various scripting tasks.
        curl \
        # wget/install-tl requires capability to check certificate validity.
        # Without this, executing `install-tl` fails with:
        #
        # install-tl: TLPDB::from_file could not initialize from: https://<mirror>/pub/ctan/systems/texlive/tlnet/tlpkg/texlive.tlpdb
        # install-tl: Maybe the repository setting should be changed.
        # install-tl: More info: https://tug.org/texlive/acquire.html
        #
        # Using `install-tl -v`, found out that mirrors use HTTPS, for which the
        # underlying `wget` (as used by `install-tl`) returns:
        #
        # ERROR: The certificate of '<mirror>' is not trusted.
        # ERROR: The certificate of '<mirror>' doesn't have a known issuer.
        #
        # This is resolved by installing:
        ca-certificates \
        # Update Perl, otherwise: "Can't locate Pod/Usage.pm in @INC" in install-tl
        # script; Perl is already installed, but do not use `upgrade`, see
        # https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
        perl \
        # Usually, `latexmk` is THE tool to use to automate, in a `make`-like style,
        # LaTeX (PDF) file generation. However, if that is not enough, the following
        # will fill the gaps and cover all other use cases:
        make


FROM BASE as PREPARE

# Cannot share ARGs over multiple stages, see also:
# https://github.com/moby/moby/issues/37345.
# Therefore, work in root (no so `WORKDIR`), so in later stages, the location of
# files copied from this stage does not have to be guessed/WET.

# Using an ARG with 'TEX' in the name, TeXLive will warn:
#
#  ----------------------------------------------------------------------
#  The following environment variables contain the string "tex"
#  (case-independent).  If you're doing anything but adding personal
#  directories to the system paths, they may well cause trouble somewhere
#  while running TeX. If you encounter problems, try unsetting them.
#  Please ignore spurious matches unrelated to TeX.

#     TEXPROFILE_FILE=texlive.profile
#  ----------------------------------------------------------------------
#
# This also happens when the *value* contains 'TEX'.
# `ARG`s are only set during Docker image build-time, so this warning should be void.

ARG TL_VERSION=latest
ARG TL_INSTALL_ARCHIVE="install-tl-unx.tar.gz"
ARG EISVOGEL_ARCHIVE="Eisvogel.tar.gz"
ARG INSTALL_TL_DIR="install-tl"

COPY texlive.sh .

RUN \
    # Get appropriate installer for the TeXLive version to be installed:
    ./texlive.sh get ${TL_VERSION} && \
    # Get Eisvogel LaTeX template for pandoc,
    # see also #175 in that repo.
    wget https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/${EISVOGEL_ARCHIVE}

RUN \
    mkdir ${INSTALL_TL_DIR} && \
    # Save archive to predictable directory, in case its name ever changes; see
    # https://unix.stackexchange.com/a/11019/374985.
    # The archive comes with a name in the form of 'install-tl-YYYYMMDD' from the source,
    # which is of course unpredictable.
    tar --extract --file=${TL_INSTALL_ARCHIVE} --directory=${INSTALL_TL_DIR} --strip-components 1 && \
    \
    # Prepare Eisvogel pandoc template (yields `eisvogel.tex` among other things):
    tar --extract --file=${EISVOGEL_ARCHIVE}


FROM BASE as MAIN

# Metadata
ARG BUILD_DATE="n/a"
ARG VCS_REF="n/a"

ARG TL_VERSION="latest"
ARG TL_PROFILE="texlive.profile"

# Label according to http://label-schema.org/rc1/ to have some metadata in the image.
# This is important e.g. to know *when* an image was built. Depending on that, it can
# contain different software versions (even if the base image is specified as a fixed
# version).
LABEL \
    maintainer="Alex Povel <alex.povel@tuhh.de>" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.description="TeXLive with most packages, JavaRE, Inkscape, pandoc and more" \
    org.label-schema.url="https://collaborating.tuhh.de/alex/latex-git-cookbook" \
    org.label-schema.vcs-url="https://github.com/alexpovel/latex-extras-docker" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.schema-version="1.0"

# User to install and run LaTeX as.
# This is a security and convenience measure: by default, containers run as root.
# To work and compile PDFs using this container, you will need to map volumes into it
# from your host machine. Those bind-mounts will then be accessed as root from this
# container, and any generated files will also be owned by root. This is inconvenient at
# best and dangerous at worst.
# The generated user here will have IDs of 1000:1000. If your local user also has those
# (the case for single-user Debians etc.), your local user will already have correct
# ownership of all files generated by the user we create here.
ARG USER="tex"
RUN useradd --create-home ${USER}

ARG INSTALL_DIR="/install/"
WORKDIR ${INSTALL_DIR}

# Copy custom file containing TeXLive installation instructions
COPY ${TL_PROFILE} .
COPY --from=PREPARE /install-tl/ /texlive.sh ./

# Change that file's suffix to .latex, move to where pandoc looks for templates, see
# https://pandoc.org/MANUAL.html#option--data-dir
COPY --from=PREPARE /eisvogel.tex /usr/share/pandoc/data/templates/eisvogel.latex

# See: https://www.tug.org/texlive/doc/install-tl.html#ENVIRONMENT-VARIABLES,
# https://tex.stackexchange.com/a/470341/120853.
# IMPORTANT: Put these into the actual designated container's user's home for full
# write access. Otherwise, we run into all sorts of annoying errors, like
# https://tex.stackexchange.com/q/571021/120853
ARG TEXLIVE_INSTALL_TEXMFCONFIG="/home/${USER}/.texlive/texmf-config"
ARG TEXLIVE_INSTALL_TEXMFVAR="/home/${USER}/.texlive/texmf-var"
ARG TEXLIVE_INSTALL_TEXMFHOME="/home/${USER}/texmf"

# (Large) LaTeX layer
RUN ./texlive.sh install ${TL_VERSION}

# Remove no longer needed installation workdir.
# Cannot run this earlier because it would be recreated for any succeeding `RUN`
# instructions.
# Therefore, change `WORKDIR` first, then delete the old one.
WORKDIR /${USER}
RUN rm --recursive ${INSTALL_DIR}

# Layer with graphical and auxiliary tools
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
    # headless, 25% of normal size:
    default-jre-headless \
    # No headless inkscape available currently:
    inkscape \
    # nox (no X Window System): CLI version, 10% of normal size:
    gnuplot-nox \
    # For various conversion tasks, e.g. EPS -> PDF (for legacy support):
    ghostscript

# Pandoc layer; not required for LaTeX compilation, but useful for document conversions
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
    # librsvg2 for 'rsvg-convert' used by pandoc to convert SVGs when embedding
    # into PDF
    librsvg2-bin \
    pandoc

USER ${USER}

# Load font cache, has to be done on each compilation otherwise
# ("luaotfload | db : Font names database not found, generating new one.").
# If not found, e.g. TeXLive 2012 and earlier, simply skip it. Will return exit code
# 0 and allow the build to continue.
# Warning: This is USER-specific. If the current `USER` for which we run this is not
# the container user, the font will be regenerated for that new user.
RUN luaotfload-tool --update || echo "luaotfload-tool did not succeed, skipping."

# The default parameters to the entrypoint; overridden if any arguments are given to
# `docker run`.
# `lualatex` usage for `latexmk` implies PDF generation, otherwise DVI is generated.
CMD [ "--lualatex" ]

# Allow container to run as an executable; override with `--entrypoint`.
# Allows to simply `run` the image without specifying any executable.
# If `latexmk` is called without a file argument, it will run on all *.tex files found.
ENTRYPOINT [ "latexmk" ]
