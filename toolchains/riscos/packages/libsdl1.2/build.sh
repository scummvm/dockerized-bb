#! /bin/sh

SDL_VERSION=08d4c52ceaa1b95f964169701beeb9f5698283c4

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL "https://github.com/libsdl-org/SDL-1.2/archive/${SDL_VERSION}.tar.gz" 'tar xzf'

do_configure
do_make
do_make install

do_clean_bdir
