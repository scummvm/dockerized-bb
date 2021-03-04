#! /bin/sh

# Stick with toolchain version
LIBPNG_VERSION=1.4.13
LIBPNG_SHA256=c94674e3088cd45bd8f130e483859fdab22a8c0f87d37fb04ed77106242f4d2a

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libpng "http://download.sourceforge.net/project/libpng/libpng14/older-releases/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${LIBPNG_SHA256}"

# Enable shared objects to make binary lighter
do_configure_shared
do_make

# Don't install man pages and binaries
do_make install-libLTLIBRARIES \
	install-binSCRIPTS \
	install-exec-hook \
	install-pkgconfigDATA \
	install-pkgincludeHEADERS \
	install-data-hook

do_clean_bdir
