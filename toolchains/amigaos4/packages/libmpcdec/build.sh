#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_lha_fetch audio/libmpcdec "libmpcdec*/"

do_lha_install

# libmpcdec.a is located in common folder where it should not and it has a bad casing, fix this
cp local/common/lib/libMPCdec.a $DESTDIR/$PREFIX/lib/libmpcdec.a

do_clean_bdir
