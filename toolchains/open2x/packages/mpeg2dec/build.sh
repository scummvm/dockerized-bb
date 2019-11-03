#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch mpeg2dec

# comment out pld instructions
sed -i 's/pld/@pld/' libmpeg2/motion_comp_arm_s.S

do_configure
do_make -C libmpeg2
do_make -C libmpeg2 install
# No need to build includes
do_make -C include install

do_clean_bdir
