#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

cp -r ${PACKAGE_DIR}/src/. .

do_make N64PREFIX="${N64SDK}/bin/mips64-"

# Poor man install
mkdir -p "${N64SDK}/hkz-libn64/"
cp *.h *.a bootcode font.raw header n64ld_cpp.x "${N64SDK}/hkz-libn64/"

do_clean_bdir
