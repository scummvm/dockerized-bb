#! /bin/sh

SONIVOX_VERSION=3.6.14

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch sonivox \
		"https://github.com/pedrolcl/sonivox/archive/refs/tags/v${SONIVOX_VERSION}.tar.gz" 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Windows for Windows

do_cmake -DBUILD_SONIVOX_SHARED=OFF -DBUILD_TESTING=OFF -DBUILD_EXAMPLE=OFF "$@"
do_make
do_make install

do_clean_bdir
