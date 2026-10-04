#! /bin/sh

OSMESA_VERSION=7.7.1

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch Mesa "https://archive.mesa3d.org/older-versions/7.x/${OSMESA_VERSION}/MesaLib-${OSMESA_VERSION}.tar.bz2" 'tar xjf'

do_configure --without-x --enable-static --with-driver=osmesa --disable-egl --disable-glu --disable-glw --disable-gallium
do_make
do_make install
# The archive is installed without a symbol index
${RANLIB} "${LIBDIR}/libOSMesa.a"

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
