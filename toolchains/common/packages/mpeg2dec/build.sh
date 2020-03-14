#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch mpeg2dec

# Apply patches to configure.ac brought by Debian
autoreconf -fi

do_configure
do_make -C libmpeg2
do_make -C libmpeg2 install
# No need to build includes
do_make -C include install

do_clean_bdir
