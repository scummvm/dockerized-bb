PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

osxcross-macports ${MACOSX_PORTS_ARCH_ARG} -s install libsdl2
rm -Rf ${TARGET_DIR}/macports/cache

# Fix paths in sdl2-config
sed -i -e "s#^prefix=.*\$#prefix=${DESTDIR}/${PREFIX}#" ${DESTDIR}/${PREFIX}/bin/sdl2-config

do_clean_bdir
