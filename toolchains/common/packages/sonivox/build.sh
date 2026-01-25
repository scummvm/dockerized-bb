#! /bin/sh

SONIVOX_VERSION=4.0.0

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch sonivox \
		"https://github.com/EmbeddedSynth/sonivox/archive/refs/tags/v${SONIVOX_VERSION}.tar.gz" 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Windows for Windows

do_cmake -DBUILD_TESTING=OFF -DBUILD_APPLICATION=OFF "$@"
do_make
do_make install

do_clean_bdir
