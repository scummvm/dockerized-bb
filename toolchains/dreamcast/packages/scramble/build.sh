#! /bin/sh

# This package comes from Marcus Comstedt website: http://mc.pp.se/dc/sw.html
# It's directly bundled here as it didn't changed since 2000(!) and to prevent it from being lost

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

cc -ansi -o scramble "${PACKAGE_DIR}"/scramble.c

install -D -t "${DCTOOLCHAIN}"/bin/ scramble

do_clean_bdir
