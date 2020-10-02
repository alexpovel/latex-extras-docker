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

HISTORIC_BASE_URL="ftp://tug.org/historic/systems/texlive"
REGULAR_BASE_URL="http://mirror.ctan.org/systems/texlive/tlnet"

case ${ACTION} in
    "get")
        if [[ ${VERSION} == "latest" ]]
        then
            # Get from default, current repository
            wget ${REGULAR_BASE_URL}/${TL_ARCHIVE}
        else
            # Get from historic repository
            wget ${HISTORIC_BASE_URL}/${VERSION}/${TL_ARCHIVE}
        fi
    ;;
    "install")
        if [[ ${VERSION} == "latest" ]]
        then
            # Install using default, current repository
            ./install-tl \
                --profile=${TL_PROFILE}
        else
            # Install using historic repository (`install-tl` script and repository
            # versions need to match)
            ./install-tl \
                --profile=${TL_PROFILE} \
                --repository=${HISTORIC_BASE_URL}/${VERSION}/tlnet-final
        fi
    ;;
    *)
        echo "Input not understood."
        usage
        # From /usr/include/sysexits.h
        exit 64
esac
