#! /bin/sh

SONIVOX_VERSION=4.0.1

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch sonivox \
		"https://github.com/EmbeddedSynth/sonivox/archive/refs/tags/v${SONIVOX_VERSION}.tar.gz" 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Windows for Windows

# Don't enable FM synth as our code doesn't make use of it
do_cmake -DBUILD_TESTING=OFF -DBUILD_APPLICATION=OFF -DEAS_FM_SYNTH=OFF "$@"
do_make
do_make install

do_clean_bdir
