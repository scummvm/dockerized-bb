#! /bin/sh

# Stick with toolchain version
SDL_NET_VERSION=1.2.8
SDL_NET_SHA256=5f4a7a8bb884f793c278ac3f3713be41980c5eedccecff0260411347714facb4

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL_net "https://www.libsdl.org/projects/SDL_net/release/SDL_net-${SDL_NET_VERSION}.tar.gz" 'tar xzf' \
	"sha256:${SDL_NET_SHA256}"

do_configure_shared \
	--with-sdl-prefix="${PREFIX}"

do_make
do_make install

do_clean_bdir
