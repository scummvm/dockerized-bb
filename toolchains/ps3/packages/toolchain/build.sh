#! /bin/sh

TOOLCHAIN_VERSION=c6c17413a89ea1cd6a1ba2700d87e11fd87582ee

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch ps3toolchain "https://github.com/ps3aqua/ps3toolchain/archive/${TOOLCHAIN_VERSION}.tar.gz" 'tar xzf'

# export PATH to please toolchain.sh
export PATH=$PATH:$PS3DEV/bin:$PS3DEV/ppu/bin:$PS3DEV/spu/bin

# Use -e to stop on error
sh -e ./toolchain.sh

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
