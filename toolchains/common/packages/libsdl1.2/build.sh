#! /bin/sh

SDL_VERSION=1af51022b4e951bf10b8c9429ba5888e70c2782f

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL "https://github.com/libsdl-org/SDL-1.2/archive/${SDL_VERSION}.tar.gz" 'tar xzf'

do_configure "$@"
do_make
do_make install

do_clean_bdir
