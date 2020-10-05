#!/bin/bash

# Script to adjust the repositories of a Debian install in case they are outdated,
# aka the Debian version is an archived one.

# Debian releases:
#
# bullseye=11
# buster=10
# stretch=9
# jessie=8
# wheezy=7
# squeeze=6.0
# lenny=5.0
# etch=4.0
# sarge=3.1
# woody=3.0
# potato=2.2
# slink=2.1
# hamm=2.0
#
# See:
# https://www.debian.org/releases/
# https://www.debian.org/distrib/archive

# Little hack to get current Debian's codename, like 'buster'.
# Source: https://unix.stackexchange.com/a/253476/374985
CODENAME=$(dpkg --status tzdata | grep "Provides" | cut -f2 -d'-')
SOURCES="/etc/apt/sources.list"

echo "This Debian release is: ${CODENAME}"

# Cannot use curl, might not be available yet and cannot install yet.
apt-get update

if [ "$?" -eq 100 ]
then
    echo "Release is probably not current, setting ${SOURCES} to use the archive."
    echo "deb http://archive.debian.org/debian/ ${CODENAME} contrib main non-free" > ${SOURCES}
    echo "deb-src http://archive.debian.org/debian/ ${CODENAME} contrib main non-free" >> ${SOURCES}
    echo "Trying update again."
    apt-get update
else
    echo "Release looks current, no action needed."
fi
