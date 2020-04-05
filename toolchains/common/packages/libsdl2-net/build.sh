#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libsdl2-net

./autogen.sh
do_configure

# showinterfaces.c indirectly includes SDL_main.h which #defines main to
# SDL_main when __ANDROID__ is defined, so it won't compile in the usual manner,
# so just stub it out
echo 'int main(){return 0;}' > showinterfaces.c

do_make
do_make install

do_clean_bdir
