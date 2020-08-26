#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_lha_fetch misc/libcurl "SDK"

do_lha_install

#chmod +x "$PREFIX/bin/curl-config"
#rm "$PREFIX/bin/curl-config"
# Fix specific part of curl-config
sed -i -e 's#-L/SDK/local/newlib#-L${exec_prefix}#' "$PREFIX/bin/curl-config"

do_clean_bdir
