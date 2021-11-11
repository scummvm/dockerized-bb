#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

target=$1
version=$2

do_http_fetch "${target}-toolchain" "http://od.abstraction.se/opendingux/toolchain/opendingux-${target}-toolchain.${version}.tar.xz" 'tar xJf'

cd ..

mkdir -p "${OPENDINGUX_ROOT}/"
mv "${target}-toolchain" "${OPENDINGUX_ROOT}/"

"${OPENDINGUX_ROOT}/${target}-toolchain/relocate-sdk.sh"

do_clean_bdir
