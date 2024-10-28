#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_lha_fetch audio/libmpcdec "libmpcdec*/"

find . -depth -type d -name .svn -exec rm -rf '{}' ';'

do_lha_install

do_clean_bdir
