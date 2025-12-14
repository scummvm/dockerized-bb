#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libpng1.6
do_configure
do_make

# Don't install man pages and binaries
do_make install-libLTLIBRARIES \
	install-binSCRIPTS \
	install-pkgconfigDATA \
	install-pkgincludeHEADERS \
	install-nodist_pkgincludeHEADERS

# As we install everything manually we must handle dependencies ourselves
# Run these after the other ones as they depends on them
do_make install-header-links \
	install-library-links \
	install-libpng-pc \
	install-libpng-config

do_clean_bdir
