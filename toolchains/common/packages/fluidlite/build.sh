#! /bin/sh

FLUIDLITE_VERSION=eaacb5f8d089a31084777de490d10c1c9b9c0c51

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
