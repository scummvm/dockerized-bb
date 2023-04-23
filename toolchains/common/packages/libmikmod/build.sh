#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libmikmod

do_configure --disable-doc --disable-alldrv --disable-threads --disable-dl
do_make
do_make install

do_clean_bdir
