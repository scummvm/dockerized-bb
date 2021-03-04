#! /bin/sh

# Stick with toolchain version
SDL_NET_VERSION=2.0.0
SDL_NET_SHA256=d715be30783cc99e541626da52079e308060b21d4f7b95f0224b1d06c1faacab

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL2_net "https://www.libsdl.org/projects/SDL_net/release/SDL2_net-${SDL_NET_VERSION}.tar.gz" 'tar xzf' \
	"sha256:${SDL_NET_SHA256}"

do_configure_shared \
	--with-sdl-prefix="${PREFIX}" \
	--disable-static \
	--disable-gui

do_make
do_make install

do_clean_bdir
