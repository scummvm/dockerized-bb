#! /bin/sh

VASM_VERSION=2_0f

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch vasm "http://phoenix.owl.de/tags/vasm${VASM_VERSION}.tar.gz" 'tar xzf'
do_make CPU=m68k SYNTAX=mot
install -s vasmm68k_mot "${ATARI_TOOLCHAIN}/bin"

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
