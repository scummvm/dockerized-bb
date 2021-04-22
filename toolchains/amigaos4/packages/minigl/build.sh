#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# HACK: do_lha_fetch expects a development library which minigl isn't
do_lha_fetch ../../driver/graphics/minigl MiniGL/SDK

do_lha_install

do_clean_bdir
