#! /bin/sh

# Stick with toolchain version
ZLIB_VERSION=1.2.5
ZLIB_SHA256=6064e52e513facb0fbb7998c6413406cf253cfb986063d68f4771c2bf7a3f958

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
