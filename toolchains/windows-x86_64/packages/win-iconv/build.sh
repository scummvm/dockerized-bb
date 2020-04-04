#! /bin/sh

WIN_ICONV_VERSION=0.0.8

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch win-iconv "https://github.com/win-iconv/win-iconv/archive/v${WIN_ICONV_VERSION}.tar.gz" 'tar xzf'

do_make libiconv.a

# Install manually to install the bare minimum
install -m 0644 -D iconv.h "${PREFIX}/include/iconv.h"
install -m 0644 -D libiconv.a "${PREFIX}/lib/libiconv.a"

do_clean_bdir
