#! /bin/sh

# Stick with toolchain version
ZLIB_VERSION=1.2.8
ZLIB_SHA256=36658cb768a54c1d4dec43c3116c27ed893e88b02ecfcb44f2166f9c0b7f2a0d

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch zlib "http://www.zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz" 'tar xzf' "sha256:${ZLIB_SHA256}"

# Enable shared objects
./configure --prefix=$PREFIX --shared
do_make
do_make install

do_clean_bdir
