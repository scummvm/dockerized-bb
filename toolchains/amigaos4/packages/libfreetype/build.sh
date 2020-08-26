#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_lha_fetch graphics/libfreetype "Freetype2/SDK"

do_lha_install

#chmod +x "$PREFIX/bin/freetype-config"
#rm "$PREFIX/bin/freetype-config"

do_clean_bdir
