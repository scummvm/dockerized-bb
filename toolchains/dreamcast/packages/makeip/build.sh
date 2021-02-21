#! /bin/sh

# This package comes from Marcus Comstedt website: http://mc.pp.se/dc/sw.html
# It's directly bundled here as it didn't changed since 2000(!) and to prevent it from being lost

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

cc -o makeip "${PACKAGE_DIR}"/makeip.c

install -D -t "${DCTOOLCHAIN}"/bin/ makeip
install -D -t "${DCTOOLCHAIN}"/share/makeip/ "${PACKAGE_DIR}"/IP.TMPL
install -D -t "${DCTOOLCHAIN}"/share/makeip/ "${PACKAGE_DIR}"/ip.txt

do_clean_bdir
