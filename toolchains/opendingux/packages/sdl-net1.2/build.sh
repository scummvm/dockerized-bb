#! /bin/sh

# Stick with toolchain version
SDL_NET_VERSION=1.2.7
SDL_NET_SHA256=2ce7c84e62ff8117b9f205758bcce68ea603e08bc9d6936ded343735b8b77c53

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL_net "https://www.libsdl.org/projects/SDL_net/release/SDL_net-${SDL_NET_VERSION}.tar.gz" 'tar xzf' \
	"sha256:${SDL_NET_SHA256}"

# Override config.guess and config.sub with modern versions
cp /usr/share/misc/config.guess /usr/share/misc/config.sub .

do_configure_shared \
	--with-sdl-prefix="${PREFIX}"

do_make
do_make install

do_clean_bdir
