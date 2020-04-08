#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# Android already comes with zlib but it doesn't advertise it with pkg-config
# As other libraries (libpng) requires it, just create a dummy .pc file

# Determine zlib version (the same way original zlib configure does)
ZLIB_VERSION=$(sed -n -e '/VERSION "/s/.*"\(.*\)".*/\1/p' < ${PREFIX}/include/zlib.h)
if [ -z "${ZLIB_VERSION}" ]; then
	error "Can't find Android zlib version"
fi

cat > zlib.pc <<EOF
Name: zlib
Description: zlib compression library
Version: ${ZLIB_VERSION}
Requires:
Libs: -lz
Cflags:
EOF

pkgconfigdir=${PREFIX}/lib/${TARGET}/${API}/pkgconfig

# These steps are inspired from original zlib Makefile.in
mkdir -p ${DESTDIR}/${pkgconfigdir}
rm -f ${DESTDIR}/${pkgconfigdir}/zlib.pc
cp zlib.pc ${DESTDIR}/${pkgconfigdir}
chmod 644 ${DESTDIR}/${pkgconfigdir}/zlib.pc

do_clean_bdir
