#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# HACK: do_lha_fetch expects a development library which codesets isn't
do_lha_fetch ../../library/misc/codesets codesets

mkdir -p $DESTDIR/$PREFIX/include
cp -R Developer/include/. $DESTDIR/$PREFIX/include/

mkdir -p $DESTDIR/$PREFIX/lib
cp Libs/AmigaOS4/codesets.library $DESTDIR/$PREFIX/lib

do_clean_bdir
