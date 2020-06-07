#! /bin/sh

ISJPCM_VERSION=5cc412ecd141ece48acf9d90e5d4339068cbd7dc

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch isjpcm "https://github.com/AKuHAK/isjpcm/archive/${ISJPCM_VERSION}.tar.gz" 'tar xzf'

make
make install

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
