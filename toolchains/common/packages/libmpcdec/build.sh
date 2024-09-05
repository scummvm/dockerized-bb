#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libmpc

autoreconf -fi

do_configure "$@"

do_make -C include
do_make -C libmpcdec

do_make -C include install
do_make -C libmpcdec install

do_clean_bdir
