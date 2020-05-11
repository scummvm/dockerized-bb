#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch zip

do_make -f unix/Makefile generic LOCAL_ZIP=-DFORRISCOS
cp zip /usr/local/bin/

do_clean_bdir
