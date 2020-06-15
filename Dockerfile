FROM debian:bullseye

LABEL maintainer="Alex Povel"
LABEL description="TeXLive with most packages, Java RE, gnuplot, pandoc and InkScape"

WORKDIR /tmp/

# Like COPY, but can fetch URLs; automatic archive unpacking no longer possible though.
# URL gets latest TeXLive installer from close location.
ADD http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz .

# Copy custom file containing TeXLive installation instructions
COPY texlive.profile .


# Base texlive layer; large layer, so separate.
# Use apt-get over apt, see https://askubuntu.com/a/990838/978477
RUN apt-get update -y && \
    apt-get install -y \
        # Update Perl, otherwise: "Can't locate Pod/Usage.pm in @INC" in install-tl
        # script; Perl is already installed, but do not use `upgrade`, see
        # https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
        perl \
        # wget for install-tl script to download TeXLive
        wget && \
    mkdir install-tl && \
    # Save archive to predictable directory, in case its name ever changes; see
    # https://unix.stackexchange.com/a/11019/374985
    tar --extract --file=install-tl-unx.tar.gz -C install-tl --strip-components 1 && \
    # Use custom profile for unattended install
    perl install-tl/install-tl --profile=texlive.profile && \
    # Load font cache, has to be done on each compilation otherwise
    # (luaotfload | db : Font names database not found, generating new one.)
    luaotfload-tool --update


# Layer with graphical and auxiliary tools
RUN apt-get update && \
    apt-get install -y \
        # headless, 25% of normal size:
        default-jre-headless \
        inkscape \
        # nox (no X Window System): CLI version, 10% of normal size:
        gnuplot-nox


# Pandoc layer; not required for LaTeX compilation, but useful for document conversions
RUN apt-get update && \
    apt-get install -y \
        curl \
        # librsvg2 for 'rsvg-convert' used by pandoc to convert SVGs when embedding
        # into PDF
        librsvg2-bin \
        pandoc && \
    # Get URL to latest Eisvogel pandoc latex template release, then download archive.
    # Suppress wget output (no file), instead write to stdout (-); avoids saving file,
    # see https://unix.stackexchange.com/a/85195/374985
    wget --quiet --output-document=- $(\
        curl -s https://api.github.com/repos/Wandmalfarbe/pandoc-latex-template/releases/latest | \
        grep "browser_download_url.*\.tar\.gz" | \
        cut -d "\"" -f 4 \
    ) | \
    # pipe to tar, read from stdout from wget, extract only a single file
    tar --extract --gzip --file=- eisvogel.tex && \
    # Change that file's suffix to .latex, move to where pandoc looks for templates, see
    # https://pandoc.org/MANUAL.html#option--data-dir
    mv eisvogel.tex /usr/share/pandoc/data/templates/eisvogel.latex
