#! /bin/sh

USOUND_VERSION=49c6bd69d0363a59766b9a8742af54982f3f6221

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
