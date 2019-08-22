#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libmad
# Unlike the other packages, for some reason libmad does not
# auto-apply quilt patches from the debian directory, which are
# needed to (among other things) avoid compilation failures due to
# the use of a flag `-fforce-mem`` which was removed in GCC 4.3.
dh_quilt_patch

touch NEWS AUTHORS ChangeLog
autoreconf -fi

do_configure
do_make
do_make install

do_clean_bdir
