#! /bin/sh

SDL_PSL1GHT_VERSION=d9763a92004369ba3d2384553eb84b2732be3ca9

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch sdl_psl1ght "https://github.com/bgK/sdl_psl1ght/archive/${SDL_PSL1GHT_VERSION}.tar.gz" 'tar xzf'

# export PATH to please script.sh
export PATH=$PATH:$PS3DEV/bin:$PS3DEV/ppu/bin:$PS3DEV/spu/bin

# Use -e to stop on error
bash -e ./script.sh

# script.sh has compilation and installation commented out
do_make
do_make install

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
