#! /bin/sh

# Stick with toolchain version
LIBPNG_VERSION=1.2.46
LIBPNG_SHA256=a5e796e1802b2e221498bda09ff9850bc7ec9068b6788948cc2c42af213914d8

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libpng "http://download.sourceforge.net/project/libpng/libpng12/older-releases/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.bz2" \
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
