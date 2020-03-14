#! /bin/sh

PKG=master-linux-v1097/vitasdk-x86_64-linux-gnu-2020-02-16_12-00-03.tar.bz2

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch vitasdk "https://github.com/vitasdk/autobuilds/releases/download/$PKG" 'tar xjf'

cp -a . $DESTDIR/$VITASDK

do_clean_bdir
