#! /bin/sh

TOOLCHAIN_VERSION=275f440b8375b9e7ec0c34c802c2da3ff4c38105
export PSL1GHT_VERSION=4b2fe11a09eb758db6a0a7c31ec1dbf626e3ba0d
export PS3LIBRARIES_VERSION=a26a929c18de8deb1151d83d97e8774ca1bdcc98
export SDL_PSL1GHT_VERSION=eb42f8bd81173003336d7c8f019de1f4aa2f3575
export SDL_PSL1GHT_LIBS_VERSION=839ae9908f26fa6d11a8126eca213e9f991d5dd6
export NORSX_VERSION=f8519cd7c4d1f64d38b7621afcb4b4efbd37dbbc

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
