#! /bin/sh

CCTOOLS_PORT_VERSION=634a084377ee2e2932c66459b0396edf76da2e9f
export LDID_VERSION=4bf8f4d60384a0693dbbe2084ce62a35bfeb87ab

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch cctools-port "https://github.com/tpoechtrager/cctools-port.git" "${CCTOOLS_PORT_VERSION}"

TARGETDIR="${TARGET_DIR}" ./usage_examples/ios_toolchain/build.sh "${SDK_DIR}/"* armv7

do_clean_bdir
