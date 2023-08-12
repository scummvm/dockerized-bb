#! /bin/sh

SDL2_VERSION=2.28.0

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch SDL2 "https://github.com/AmigaPorts/SDL-2.0/releases/download/v$SDL2_VERSION-amigaos4/SDL2.lha" 'lha x'

cd SDK

do_lha_install

do_clean_bdir
