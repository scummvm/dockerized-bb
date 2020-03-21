#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch fluidsynth-lite \
	'https://github.com/Doom64/fluidsynth-lite/archive/c539a8d9270ba5a3f7d6e460606483fc2ab1eb61.tar.gz' 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Windows for Windows

do_cmake "$@"
do_make
do_make install

do_clean_bdir
