#! /bin/sh

VITA_VERSION=2.527
# This one must be updated as well
PKG_DATE=2024-08-09_11-28-39

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch vitasdk "https://github.com/vitasdk/autobuilds/releases/download/master-linux-v$VITA_VERSION/vitasdk-x86_64-linux-gnu-$PKG_DATE.tar.bz2" 'tar xjf'

cp -a . $DESTDIR/$VITASDK

do_clean_bdir
