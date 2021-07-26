#! /bin/sh

HKZ_LIBN64_VERSION=09112010-1

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

cp -r ${PACKAGE_DIR} ${N64SDK}/hkz-libn64
cd ${N64SDK}/hkz-libn64
do_make N64PREFIX=${N64SDK}/bin/mips64-
rm *.o

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
