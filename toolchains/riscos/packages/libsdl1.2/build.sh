#! /bin/sh

SDL_VERSION=0b7f217d0dbbe991f4284581d9f97440ad986c1d

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL- "https://hg.libsdl.org/SDL/archive/$SDL_VERSION.tar.bz2" 'tar xjf'

do_configure
do_make
do_make install

do_clean_bdir
