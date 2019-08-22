#! /bin/sh
# This library only needs to be compiled if you are planning on using a
# precompiled FreeType that expects it to exist. Otherwise, it is used only for
# an obsolete X11 bitmap font format that ScummVM will never use.

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch bzip2

do_make
do_make install

# Manually build and install only the static library and header
#do_make libbz2.a
#mkdir -p "$PREFIX/lib"
#cp -f libbz2.a "$PREFIX/lib"
#chmod a+r "$PREFIX/lib/libbz2.a"
#mkdir -p "$PREFIX/include"
#cp -f bzlib.h "$PREFIX/include"
#chmod a+r "$PREFIX/include/bzlib.h"

do_clean_bdir
