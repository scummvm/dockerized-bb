#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libvorbis

# Fix clang compilation
sed -i -e '/CFLAGS/s:-mno-ieee-fp::' configure.ac

# Avoid compiling and installing doc
sed -i -e 's/^\(SUBDIRS.*\) doc/\1/' Makefile.am

autoreconf -fi -I m4
do_configure
do_make
do_make install

do_clean_bdir
