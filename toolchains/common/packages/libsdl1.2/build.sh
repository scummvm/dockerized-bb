#! /bin/sh

SDL_VERSION=d6200ed17f8584b20a3e20f9bd571ece87db40e2

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL "https://github.com/libsdl-org/SDL-1.2/archive/${SDL_VERSION}.tar.gz" 'tar xzf'

do_configure
do_make
do_make install

do_clean_bdir
