#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch directx-devel "http://www.libsdl.org/extras/win32/common/directx-devel.tar.gz" 'tar --one-top-level -xzf'

cp include/*.h "${PREFIX}"/include

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
