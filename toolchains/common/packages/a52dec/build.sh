#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch a52dec

sed -i '/AC_C_ALWAYS_INLINE/d' configure.in

autoreconf -fi
do_configure
do_make -C liba52
do_make -C liba52 install
# No need to build includes
do_make -C include install

do_clean_bdir
