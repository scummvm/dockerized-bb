#! /bin/sh

LIBRARIES_VERSION=6da19fa0de838a1e99519f471b48be654a7215ed

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch ps3libraries "https://github.com/ps3aqua/ps3libraries/archive/${LIBRARIES_VERSION}.tar.gz" 'tar xzf'

# export PATH to please libraries.sh
export PATH=$PATH:$PS3DEV/bin:$PS3DEV/ppu/bin:$PS3DEV/spu/bin

# Use -e to stop on error
sh -e ./libraries.sh

# Toolchain portlibs install binaries that we don't need and can't run on host
find $PS3DEV/portlibs/ppu/bin -type f '!' -name '*-config' -delete

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
