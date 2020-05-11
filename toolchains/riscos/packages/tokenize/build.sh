#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_svn_fetch tokenize svn://svn.riscos.info/tokenize/trunk/ -r32

do_make obj buildlinux/tokenize
cp buildlinux/tokenize /usr/local/bin/

do_clean_bdir
