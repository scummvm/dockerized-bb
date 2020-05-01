#! /bin/sh

# Caanoo toolchain uses zlib 1.2.3 stick with it
ZLIB_VERSION=1.2.3
ZLIB_SHA256=1795c7d067a43174113fdf03447532f373e1c6c57c08d61d9e4e9be5e244b05e

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch zlib "http://www.zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz" 'tar xzf' "sha256:${ZLIB_SHA256}"

# Enable shared objects
# There is a bug in configure script when AR is specified, it eats the rc argument
AR="$AR rc" ./configure --prefix=$PREFIX --shared
do_make
do_make install

do_clean_bdir
