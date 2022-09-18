#! /bin/sh

# Call with --with-winssl for Windows

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch curl

# pop nss and gnutls patches
# head selects the first line and tee outputs it to stderr for debug
# grep makes sure we are removing the expected patch
quilt pop |head -n1 |tee /dev/stderr |grep -qF '99_nss.patch'
quilt pop |head -n1 |tee /dev/stderr |grep -qF '90_gnutls.patch'

autoreconf -fi -I m4

do_configure --with-ssl="$PREFIX" "$@"
do_make -C lib
do_make -C lib install
# No need to build includes
do_make -C include install
do_make install-pkgconfigDATA install-binSCRIPTS

do_clean_bdir
