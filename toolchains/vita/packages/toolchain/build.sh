#! /bin/sh

VITA_VERSION=2.535
# This one must be updated as well
PKG_DATE=2025-07-20_13-03-36

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch vitasdk "https://github.com/vitasdk/autobuilds/releases/download/master-linux-v$VITA_VERSION/vitasdk-x86_64-linux-gnu-$PKG_DATE.tar.bz2" 'tar xjf'

cp -a . $DESTDIR/$VITASDK

do_clean_bdir
