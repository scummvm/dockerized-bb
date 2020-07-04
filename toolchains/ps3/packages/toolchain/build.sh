#! /bin/sh

TOOLCHAIN_VERSION=275f440b8375b9e7ec0c34c802c2da3ff4c38105

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
