#! /bin/sh

SDL_VERSION=6eaf4aee7940

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL- "https://hg.libsdl.org/SDL/archive/$SDL_VERSION.tar.bz2" 'tar xjf'

do_configure
do_make
do_make install

do_clean_bdir
