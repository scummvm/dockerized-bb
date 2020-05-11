#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_svn_fetch !OSLib https://svn.code.sf.net/p/ro-oslib/code/trunk/!OSLib -r458

do_make -C Tools/BindHelp install bindir="/usr/local/bin"

do_clean_bdir
