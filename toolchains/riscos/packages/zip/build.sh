#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch zip

do_make -f unix/Makefile generic LOCAL_ZIP=-DFORRISCOS

mkdir -p "$GCCSDK_INSTALL_CROSSBIN"
cp zip "$GCCSDK_INSTALL_CROSSBIN"

do_clean_bdir
