#! /bin/sh

# Call with --without-simd to avoid SIMD

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libjpeg-turbo
# Rebuild configure script as it has been built on a machine without pkg-config
autoreconf -i
do_configure --without-turbojpeg "$@"
do_make

# Don't install binaries and doc
do_make install-libLTLIBRARIES \
	install-pkgconfigDATA \
	install-includeHEADERS \
	install-nodist_includeHEADERS

do_clean_bdir
