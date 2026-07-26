#! /bin/sh

LHA_VERSION=16619b066b189ef289bb8b07b37d1c38d550da99

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch lha "https://github.com/jca02266/lha/archive/${LHA_VERSION}.tar.gz" 'tar xzf'

autoreconf -vfi

# We don't use do_configure as it's a native build
./configure --prefix="${CROSS_PREFIX}"

do_make
do_make install

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
