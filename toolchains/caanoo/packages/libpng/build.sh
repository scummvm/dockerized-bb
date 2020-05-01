#! /bin/sh

# Caanoo toolchain uses libpng 1.2.33 stick with it
LIBPNG_VERSION=1.2.33
LIBPNG_SHA256=af3a8150fedaf3ea561c10c59fa828f71f732ade06e3f3d13fa453629c470800

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
