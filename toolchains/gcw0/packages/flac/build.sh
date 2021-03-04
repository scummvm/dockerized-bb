#! /bin/sh

# Stick with toolchain version
FLAC_VERSION=1.3.0
FLAC_SHA256=fa2d64aac1f77e31dfbb270aeb08f5b32e27036a52ad15e69a77e309528010dc

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch flac "http://downloads.xiph.org/releases/flac/flac-${FLAC_VERSION}.tar.xz" \
	'tar xJf' "sha256:${FLAC_SHA256}"

autoreconf -fi
do_configure_shared --disable-doxygen-docs --disable-xmms-plugin --disable-cpplibs --enable-ogg "$@"
do_make -C src/libFLAC
do_make -C src/libFLAC install
# No need to build includes
do_make -C include install

do_clean_bdir
