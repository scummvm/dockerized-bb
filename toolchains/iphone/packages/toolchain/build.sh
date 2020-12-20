#! /bin/sh

CCTOOLS_PORT_VERSION=30518813875aed656aa7f18b6d485feee25f8f87
export LDID_VERSION=4bf8f4d60384a0693dbbe2084ce62a35bfeb87ab

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch cctools-port "https://github.com/tpoechtrager/cctools-port.git" "${CCTOOLS_PORT_VERSION}"

TARGETDIR="${TARGET_DIR}" ./usage_examples/ios_toolchain/build.sh "${SDK_DIR}/"* armv7

do_clean_bdir
