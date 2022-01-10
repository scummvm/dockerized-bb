#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

JOBS=$(nproc)

do_make_bdir

do_git_fetch mxe "https://github.com/mxe/mxe.git" "${MXE_VERSION}"

# Remove ccache to prevent its compilation: we don't need it
rm src/ccache.mk

cd ..

# Install MXE
mv mxe "${MXE_DIR}"

# Install settings from package
cp "${PACKAGE_DIR}/settings.mk" "${MXE_DIR}"/

cd "${MXE_DIR}"/

# Override PREFIX on command line and not in settings.mk because else it gets overriden too late

make PREFIX="${MXE_PREFIX_DIR}" -j$JOBS check-requirements

# Build compilers
make PREFIX="${MXE_PREFIX_DIR}" -j$JOBS cc

make PREFIX="${MXE_PREFIX_DIR}" -j$JOBS clean-junk

do_clean_bdir
rm -f $HOME/.wget-hsts
