#! /bin/sh

RETROWAVE_VERSION=0.1.0

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch RetroWave \
	"https://github.com/SudoMaker/RetroWave/archive/v${RETROWAVE_VERSION}.tar.gz" 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Darwin for MacOS X

do_cmake "$@" -DRETROWAVE_BUILD_PLAYER=0
do_make
do_make install

do_clean_bdir
