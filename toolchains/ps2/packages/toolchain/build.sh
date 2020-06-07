#! /bin/sh

TOOLCHAIN_VERSION=4864a651f4efe2e7d1ce3b7d4f03564bc39bafe1
PS2SDK_VERSION=e2afe928fcf97babfa12917e54cfb48db261e914

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch ps2toolchain "https://github.com/ps2dev/ps2toolchain/archive/${TOOLCHAIN_VERSION}.tar.gz" 'tar xzf'

# export PATH to please build-all.sh
export PATH=$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin:$PS2SDK/bin

# for toolchain.sh
export PS2SDK_VERSION

# Use -e to stop on error
bash -e ./toolchain.sh

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
