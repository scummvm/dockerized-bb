#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# Globbing will occur where package is extracted
do_lha_fetch graphics/giflib "giflib-*/SDK"

do_lha_install

do_clean_bdir
