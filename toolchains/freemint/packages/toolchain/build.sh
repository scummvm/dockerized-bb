#! /bin/sh

# TODO: Use fixed revisions for binutils, gcc, mintlib, mintbin and fdlibm
TOOLCHAIN_VERSION=b115a55c606cbf4c07a5fd199b2c2eb5b28c4725

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch m68k-atari-mint-build "https://github.com/mikrosk/m68k-atari-mint-build/archive/${TOOLCHAIN_VERSION}.tar.gz" 'tar xzf'

# TODO: Build the m68020-60 and 5475 toolchains as well
do_make m68000-skip-native

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
