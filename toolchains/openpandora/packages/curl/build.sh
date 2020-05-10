#! /bin/sh

# OpenPandora firmware uses curl 7.20.0 stick with it
CURL_VERSION=7.20.0
CURL_SHA256=eb516915da615d8f6b2b855004d5d4b19c468f080e3736d7a73c5599b9acab11

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch curl "http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${CURL_SHA256}"

do_configure_shared --with-gnutls="$PREFIX"
do_make -C lib
do_make -C lib install
# No need to build includes
do_make -C include install
do_make install-pkgconfigDATA install-binSCRIPTS

do_clean_bdir
