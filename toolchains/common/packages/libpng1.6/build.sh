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
	install-nodist_pkgincludeHEADERS \
	install-header-links \
	install-library-links \
	install-libpng-pc

do_clean_bdir
