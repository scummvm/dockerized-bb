#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch flac

autoreconf -fi
do_configure --disable-doxygen-docs --disable-xmms-plugin --disable-cpplibs --disable-ogg
do_make -C src/libFLAC
do_make -C src/libFLAC install
# No need to build includes
do_make -C include install

do_clean_bdir
