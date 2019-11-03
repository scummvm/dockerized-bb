#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch "" 'http://web.archive.org/web/20181112050705/http://www.open2x.org/open2x/toolchains/arm-open2x-linux-apps-gcc-4.1.1-glibc-2.3.6_i686_linux.tar.bz2.zip' 'tar xjf'
mkdir -p /opt/
mv open2x /opt/

do_clean_bdir
