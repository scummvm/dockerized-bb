#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch fribidi

# Avoid compiling and installing doc, binaries and tests
sed -ie 's/^\(SUBDIRS.*\) bin doc test/\1/' Makefile.am

# Don't run configure script at the end of autogen
NOCONFIGURE=1 ./autogen.sh

do_configure
do_make
do_make install

do_clean_bdir
