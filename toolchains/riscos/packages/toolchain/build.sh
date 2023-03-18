#! /bin/sh

GCCSDK_VERSION=7735

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_svn_fetch gcc4 svn://svn.riscos.info/gccsdk/trunk/gcc4/ -r"$GCCSDK_VERSION"

echo "export GCCSDK_INSTALL_CROSSBIN=$GCCSDK_INSTALL_CROSSBIN" > gccsdk-params
echo "export GCCSDK_INSTALL_ENV=$GCCSDK_INSTALL_ENV" >> gccsdk-params

export NUMPROC=$(nproc || grep -c ^processor /proc/cpuinfo || echo 1)
export MAKEFLAGS="-j${NUMPROC}"

./build-world

do_clean_bdir
