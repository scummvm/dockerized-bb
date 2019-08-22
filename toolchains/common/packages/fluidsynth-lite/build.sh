#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch fluidsynth-lite \
	'https://github.com/Doom64/fluidsynth-lite/archive/38353444676a1788ef78eb7f835fba4fa061f3f2.tar.gz' 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Windows for Windows

do_cmake "$@"
do_make
do_make install

do_clean_bdir
