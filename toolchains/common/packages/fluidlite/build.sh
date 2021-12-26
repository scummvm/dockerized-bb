#! /bin/sh

FLUIDLITE_VERSION=acc2183fdcb9af2aca233bcfdafd5f657dce33f8

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
