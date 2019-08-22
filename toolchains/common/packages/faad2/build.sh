#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch faad2

# Avoid compiling and installing libfaad2_drm
sed -ie 's/^\(lib_LTLIBRARIES.*\) libfaad_drm.la/\1/' libfaad/Makefile.am

autoreconf -fi
do_configure
do_make -C libfaad
do_make -C libfaad install

do_clean_bdir
