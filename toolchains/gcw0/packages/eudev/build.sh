#! /bin/sh

# Stick with toolchain version
# We don't use libglib2 which is not totally perfect
EUDEV_VERSION=1.5.3

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch eudev "https://gitweb.gentoo.org/proj/eudev.git/snapshot/eudev-${EUDEV_VERSION}.tar.bz2" 'tar xjf'

autoreconf -fi

# Enable shared objects to make binary lighter
do_configure_shared \
	--disable-programs \
	--disable-gudev \
	--disable-introspection

do_make
do_make install

do_clean_bdir
