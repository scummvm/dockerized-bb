#! /bin/sh

LIBRARIES_VERSION=560b1cbed5b0e5b079e28702cde16534aecfc4d9

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
