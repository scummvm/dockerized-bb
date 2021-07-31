#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch zlib
./configure --prefix=$PREFIX --static

# Only build the library and not its samples
do_make libz.a

do_make install

do_clean_bdir
