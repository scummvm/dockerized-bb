#! /bin/sh

SDL_VERSION=ce672e4749c68fe6f1909b3f2c2722a86a5447aa

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL- "https://hg.libsdl.org/SDL/archive/$SDL_VERSION.tar.bz2" 'tar xjf'

do_configure
do_make
do_make install

do_clean_bdir
