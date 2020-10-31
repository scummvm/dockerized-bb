#! /bin/sh
# This library only needs to be compiled if you are planning on using a
# precompiled FreeType that expects it to exist. Otherwise, it is used only for
# an obsolete X11 bitmap font format that ScummVM will never use.

# This is also used when ScummVM expects the library to be here (iphone platform)

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch bzip2

# Manually build and install only the static library and header

# bzip2 Makefile redefines these variables so override them here
do_make libbz2.a CC=$CC AR=$AR RANLIB=$RANLIB

mkdir -p "$PREFIX/lib"
cp -f libbz2.a "$PREFIX/lib"
chmod a+r "$PREFIX/lib/libbz2.a"
mkdir -p "$PREFIX/include"
cp -f bzlib.h "$PREFIX/include"
chmod a+r "$PREFIX/include/bzlib.h"

do_clean_bdir
