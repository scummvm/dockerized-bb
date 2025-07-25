#! /bin/sh

EMSDK_VERSION=4.0.10

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch emsdk "https://github.com/emscripten-core/emsdk/archive/refs/tags/${EMSDK_VERSION}.tar.gz" 'tar xzf'

cd ..
mv emsdk-${EMSDK_VERSION} ${EMSDK}
cd ${EMSDK}

./emsdk install ${EMSDK_VERSION}
./emsdk activate ${EMSDK_VERSION}

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
