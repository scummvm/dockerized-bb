#! /bin/sh

# Stick with toolchain version
LIBMIKMOD_VERSION=3.3.6

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libmikmod "https://download.sourceforge.net/project/mikmod/outdated_versions/libmikmod/${LIBMIKMOD_VERSION}/libmikmod-${LIBMIKMOD_VERSION}.tar.gz" \
	'tar xzf'

autoreconf -i
do_configure_shared --localstatedir=/var --disable-esd
do_make
do_make install

do_clean_bdir
