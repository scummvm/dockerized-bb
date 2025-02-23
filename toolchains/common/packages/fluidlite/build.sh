#! /bin/sh

FLUIDLITE_VERSION=b0f187b404e393ee0a495b277154d55d7d03cbeb

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch FluidLite \
	"https://github.com/divideconcept/FluidLite/archive/${FLUIDLITE_VERSION}.tar.gz" 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Windows for Windows

do_cmake -DFLUIDLITE_BUILD_SHARED=OFF "$@"
do_make
do_make install

do_clean_bdir
