#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_lha_fetch misc/libsdl2_net "SDL2_net-*/SDK"

do_lha_install

# Set threading model as SDL2_net is multithread
sed -i -e '/^Libs:/s#$# -athread=native#' "$PREFIX/lib/pkgconfig/SDL2_net.pc"

do_clean_bdir
