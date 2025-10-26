#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch faad2

# Avoid compiling and installing DRM and fixed-point versions
sed -ie 's/faad\(_drm\(_fixed\)\?\|_fixed\)//g' CMakeLists.txt

do_cmake -DFAAD_BUILD_CLI=no "$@"
do_make
do_make install

do_clean_bdir
