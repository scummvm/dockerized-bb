#! /bin/sh

# OpenPandora firmware uses curl 7.20.0 stick with it
CURL_VERSION=7.20.0
CURL_SHA256=e12d06b551c5c9d3420b0eda20eb2861a6daab032c4d6d8fab07b56f34c8a848

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch curl "http://curl.se/download/archeology/curl-${CURL_VERSION}.tar.gz" \
	'tar xzf' "sha256:${CURL_SHA256}"

do_configure_shared --with-gnutls="$PREFIX"
do_make -C lib
do_make -C lib install
# No need to build includes
do_make -C include install
do_make install-pkgconfigDATA install-binSCRIPTS

do_clean_bdir
