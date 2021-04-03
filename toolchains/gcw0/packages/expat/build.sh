#! /bin/sh

# Stick with toolchain version
EXPAT_VERSION=2.1.0
EXPAT_SHA256=823705472f816df21c8f6aa026dd162b280806838bb55b3432b0fb1fcca7eb86

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir
# We won't use it ourselves as it's build shared, so too bad it's vulnerable but not a problem for us
do_http_fetch expat "http://download.sourceforge.net/project/expat/expat/${EXPAT_VERSION}/expat-${EXPAT_VERSION}-RENAMED-VULNERABLE-PLEASE-USE-2.3.0-INSTEAD.tar.gz" 'tar xzf' "sha256:${EXPAT_SHA256}"

do_configure_shared
do_make
do_make install

do_clean_bdir
