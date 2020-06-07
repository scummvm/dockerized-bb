#! /bin/sh

PS2SDK_PORTS_VERSION=4f8f8c51d5e92808b28f5749c077aaf57e3e9d18

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch ps2sdk-ports "https://github.com/ps2dev/ps2sdk-ports" "${PS2SDK_PORTS_VERSION}"

make zlib
make libpng
make libjpeg
make libmad
make freetype2

do_clean_bdir
