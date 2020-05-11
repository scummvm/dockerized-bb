#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL-2f82852644d1 'https://hg.libsdl.org/SDL/archive/2f82852644d1.tar.bz2' 'tar xjf'

do_configure
do_make
do_make install

do_clean_bdir
