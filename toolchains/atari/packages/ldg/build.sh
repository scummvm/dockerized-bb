#! /bin/sh

LDG_VERSION=133

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_svn_fetch ldg https://svn.code.sf.net/p/ldg/code/trunk/ldg -r"$LDG_VERSION"

cd src/devel
# All makefiles share the same object directory: clean it between CPU variants
# so that objects built for one CPU are not reused for another
do_make -f gcc.mak CC=${HOST}-gcc AR=${HOST}-ar
do_make -f gcc.mak clean
do_make -f gccm68020-60.mak CC=${HOST}-gcc AR=${HOST}-ar
do_make -f gccm68020-60.mak clean
do_make -f gccm5475.mak CC=${HOST}-gcc AR=${HOST}-ar
do_make -f gccm5475.mak clean
cd -

cp -ra include ${PREFIX}
cp -ra lib/gcc/* ${PREFIX}/lib

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
