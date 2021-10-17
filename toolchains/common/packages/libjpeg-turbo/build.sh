#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libjpeg-turbo

# In Android the assembler is not properly detected and ends up being plain clang which breaks compilation
# Force it to CC
do_cmake -DENABLE_SHARED=0 -DWITH_TURBOJPEG=0 -DREQUIRE_SIMD=1 -DCMAKE_ASM_COMPILER="$CC" "$@"
do_make

do_make install

do_clean_bdir
