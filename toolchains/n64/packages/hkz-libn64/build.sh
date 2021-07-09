#! /bin/sh

HKZ_LIBN64_VERSION=09112010-1

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch hkz-libn64 "https://web.archive.org/web/20110817231148/http://hkzlab.ipv7.net/files/consoles/hkz-libn64-${HKZ_LIBN64_VERSION}.zip" 'unzip'

do_make N64PREFIX=${N64SDK}/bin/mips64-
cp -r . ${N64SDK}/hkz-libn64

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
