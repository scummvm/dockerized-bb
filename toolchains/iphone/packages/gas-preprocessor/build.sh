#! /bin/sh

GAS_PREPROCESSOR_VERSION=42cb38cf9a41b01ff387287819adaeecebdf442d

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch gas-preprocessor "https://github.com/libjpeg-turbo/gas-preprocessor.git" "${GAS_PREPROCESSOR_VERSION}"

cp gas-preprocessor.pl ${TARGET_DIR}/bin
chmod +x ${TARGET_DIR}/bin/gas-preprocessor.pl

do_clean_bdir
