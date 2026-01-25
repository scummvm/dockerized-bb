#! /bin/sh

USOUND_VERSION=a8a81dfea8441ce8bf8e5c704df1190d8d20071e

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch usound "https://github.com/mikrosk/usound/archive/${USOUND_VERSION}.tar.gz" 'tar xf'

cp usound.h ${PREFIX}/include

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
