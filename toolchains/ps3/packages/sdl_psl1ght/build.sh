#! /bin/sh

SDL_PSL1GHT_VERSION=d2a23ee21579

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch bgK-sdl_psl1ght "https://bitbucket.org/bgK/sdl_psl1ght/get/${SDL_PSL1GHT_VERSION}.tar.gz" 'tar xzf'

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
