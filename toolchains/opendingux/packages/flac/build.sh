#! /bin/sh

# Stick with toolchain version
FLAC_VERSION=1.2.1
FLAC_SHA256=9635a44bceb478bbf2ee8a785cf6986fba525afb5fad1fd4bba73cf71f2d3edf

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch flac "http://downloads.xiph.org/releases/flac/flac-${FLAC_VERSION}.tar.gz" \
	'tar xzf' "sha256:${FLAC_SHA256}"

autoreconf -fi -I m4
do_configure_shared --disable-doxygen-docs --disable-xmms-plugin --disable-cpplibs --enable-ogg "$@"
do_make -C src/libFLAC
do_make -C src/libFLAC install
# No need to build includes
do_make -C include install

do_clean_bdir
