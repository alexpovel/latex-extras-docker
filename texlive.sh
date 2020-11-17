#!/bin/bash

# Script to fetch `install-tl` script from different sources, depending on argument
# given.

# Error out of any of the variables used here are unbound, e.g. no CLI arg given.
set -u

usage() {
    echo "Usage: $0 get|install latest|version (YYYY)"
}

if [[ $# != 2 ]]; then
    echoerr "Unsuitable number of arguments given."
    usage
    # From /usr/include/sysexits.h
    exit 64
fi

# From: https://stackoverflow.com/a/2990533/11477374
echoerr() { echo "$@" 1>&2; }

# Bind CLI arguments to explicit names:
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
            wget "${REGULAR_URL}/${TL_INSTALL_ARCHIVE}"
        else
            # Get from historic repository
            wget "${HISTORIC_URL}/${TL_INSTALL_ARCHIVE}"
        fi
    ;;
    "install")
        if [[ ${VERSION} == "latest" ]]
        then
            # Install using default, current repository
            perl install-tl \
                --profile="$TL_PROFILE"
        else
            # Install using historic repository (`install-tl` script and repository
            # versions need to match)
            perl install-tl \
                --profile="$TL_PROFILE" \
                --repository="$HISTORIC_URL"
        fi

        # For `command` usage, see:
        # https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#Bash-Builtins.
        # The following test assumes the most basic program, `tex`, is present.
        if command -v tex &> /dev/null
        then
            # If automatic `install-tl` process has already adjusted PATH, we are happy.
            echo "PATH and installation seem OK."
        else
            # Try and make installation available on path manually.
            #
            # The first wildcard expands to the architecture (should be 'x86_64-linux',
            # which might change in TeXLive upstream, so do not hardcode here),
            # the second one expands to all binaries found in that directory.
            # Only link if directory exists, else we end up with a junk symlink.
            EXPECTED_INSTALL_TEXDIR="${TEXLIVE_INSTALL_TEXDIR}/bin/*"

            # `ls` found to be more robust than `[ -d ... ]`.
            if ls "$EXPECTED_INSTALL_TEXDIR" 1>/dev/null 2>&1
            then
                SYMLINK_DESTINATION="/usr/local/bin"

                # "String contains", see: https://stackoverflow.com/a/229606/11477374
                if [[ ! ${PATH} == *${SYMLINK_DESTINATION}* ]]
                then
                    # Should never get here, but make sure.
                    echoerr "Symlink destination ${SYMLINK_DESTINATION} not in PATH (${PATH}), exiting."
                    exit 1
                fi

                echo "Symlinking TeXLive binaries in ${EXPECTED_INSTALL_TEXDIR}"
                echo "to a directory (${SYMLINK_DESTINATION}) found on PATH (${PATH})"

                # Notice the wildcard:
                ln --symbolic --verbose "$EXPECTED_INSTALL_TEXDIR"/* ${SYMLINK_DESTINATION}

                if command -v tex &> /dev/null
                then
                    echo "PATH and installation seem OK."
                else
                    echoerr "Manual symlinking failed and TeXLive did not modify PATH automatically."
                    echoerr "Exiting."
                    exit 1
                fi
            else
                echoerr "Expected TeXLive installation dir not found and TeXLive installation did not modify PATH automatically."
                echoerr "Exiting."
                exit 1
            fi
        fi
    ;;
    *)
        echoerr "Input not understood."
        usage
        # From /usr/include/sysexits.h
        exit 64
esac
