#! /bin/sh

FLUIDLITE_VERSION=7c150b021f8b7e7d4f624bbad644fd2f96e5826b

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
