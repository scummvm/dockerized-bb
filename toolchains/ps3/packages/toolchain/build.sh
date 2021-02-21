#! /bin/sh

TOOLCHAIN_VERSION=892079dbc8525e283c4ef6138f862389afe006f2
export PSL1GHT_VERSION=7920d95dcba19da126987a14262534401e91a6b4
export PS3LIBRARIES_VERSION=60e761843be6aee00d0126b0a9ce8d7d8798c5d5
export SDL_PSL1GHT_VERSION=641a8ca2efa3f775d489daa37878ada1d92c24ab
export SDL_PSL1GHT_LIBS_VERSION=5732608d69e0e7f6fc9ac2b6af906c38ab1d9475
export NORSX_VERSION=95d79a6ae8a800ad36040b836e896ff57fdd7052

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch ps3toolchain "https://github.com/ps3dev/ps3toolchain/archive/${TOOLCHAIN_VERSION}.tar.gz" 'tar xzf'

# export PATH to please toolchain.sh
export PATH=$PATH:$PS3DEV/bin:$PS3DEV/ppu/bin:$PS3DEV/spu/bin

# Use -e to stop on error
bash -e ./toolchain.sh

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
