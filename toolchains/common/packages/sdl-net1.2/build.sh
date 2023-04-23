#! /bin/sh

SDL_NET_VERSION=70b04a3087b4329d75affb766b4c84a977a546c0

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL_net "https://github.com/libsdl-org/SDL_net/archive/${SDL_NET_VERSION}.tar.gz" 'tar xzf'
do_configure --with-sdl-prefix=$PREFIX

# showinterfaces.c indirectly includes SDL_main.h which #defines main to
# SDL_main when __ANDROID__ is defined, so it won't compile in the usual manner,
# so just stub it out
echo 'int main(){return 0;}' > showinterfaces.c

do_make
do_make install

do_clean_bdir
