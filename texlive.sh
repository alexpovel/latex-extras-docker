#!/bin/bash

# Script to fetch `install-tl` script from different sources, depending on argument
# given.

# Error out of any of the variables used here are unbound, e.g. no CLI arg given.
set -u

usage() {
    echo "Usage: $0 get|install latest|version (YYYY)"
}

if [[ $# != 2 ]]; then
    echo "Unsuitable number of arguments given."
    usage
    # From /usr/include/sysexits.h
    exit 64
fi

ACTION=${1}
VERSION=${2}

# Download the `install-tl` script from the `tlnet-final` subdirectory, NOT
# from the parent directory. The latter contains an outdated, non-final `install-tl`
# script, causing this exact problem:
# https://tug.org/pipermail/tex-live/2017-June/040376.html
HISTORIC_URL="ftp://tug.org/historic/systems/texlive/${VERSION}/tlnet-final"
REGULAR_URL="http://mirror.ctan.org/systems/texlive/tlnet"

case ${ACTION} in
    "get")
        if [[ ${VERSION} == "latest" ]]
        then
            # Get from default, current repository
            wget ${REGULAR_URL}/${TL_INSTALL_ARCHIVE}
        else
            # Get from historic repository
            wget ${HISTORIC_URL}/${TL_INSTALL_ARCHIVE}
        fi
    ;;
    "install")
        if [[ ${VERSION} == "latest" ]]
        then
            # Install using default, current repository
            perl install-tl \
                --profile=${TL_PROFILE}
        else
            # Install using historic repository (`install-tl` script and repository
            # versions need to match)
            perl install-tl \
                --profile=${TL_PROFILE} \
                --repository=${HISTORIC_URL}
        fi
        # Make installation available on path manually.
        # Overwrite existing destination files (could have beeen created by TeXLive
        # installation process).
        # The first wildcard expands to the architecture (should be 'x86_64-linux'),
        # the second one expands to all binaries found in that directory.
        # Only link if directory exists, else we end up with a junk symlink.
        if [[ -d ${TEXLIVE_INSTALL_TEXDIR}/bin/*/ ]]
        then
            echo "Symlinking TeXLive binaries to a directory found on PATH..."
            ln --force --symbolic ${TEXLIVE_INSTALL_TEXDIR}/bin/*/* /usr/local/bin
        else
            echo "Expected TeXLive installation dir not found."
            echo "Relying on TeXLive installation procedure to have modified PATH on its own,"
            echo "e.g. trough the 'instopt_adjustpath 1' option."
        fi

        # This is not an exhaustive test, just a quick check. Therefore, a negative
        # result does not `exit` with non-zero.
        if command -v tex &> /dev/null
        then
            echo "PATH and installation seem OK."
        else
            echo "PATH or installation seem broken."
        fi
    ;;
    *)
        echo "Input not understood."
        usage
        # From /usr/include/sysexits.h
        exit 64
esac
