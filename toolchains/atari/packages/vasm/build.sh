#! /bin/sh

VASM_VERSION=2.0b
# Commit of release ${VASM_VERSION} in the vasm-mirror repository
VASM_COMMIT=7db75ca16f3f528463ae9846fd057040737d826b

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch vasm "https://github.com/StarWolf3000/vasm-mirror/archive/${VASM_COMMIT}.tar.gz" 'tar xf'
do_make CPU=m68k SYNTAX=mot
install -s vasmm68k_mot "${ATARI_TOOLCHAIN}/bin"

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
