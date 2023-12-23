#! /bin/sh

LDID_VERSION=2.1.5

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch osxcross "https://github.com/ProcursusTeam/ldid.git" "v${LDID_VERSION}"

# Build libplist
cd libplist
./autogen.sh --enable-static --disable-shared --without-cython
do_make

# Don't install we will manually link against in-tree library

cd ..

cc -c -o lookup2.c.o lookup2.c
c++ -c -o ldid.cpp.o -I libplist/include ldid.cpp
c++ -o ldid -L libplist/src/.libs lookup2.c.o ldid.cpp.o -lcrypto -lplist -lxml2

mkdir -p "${TARGET_DIR}"/bin =/opt/osxcross
cp ldid "${TARGET_DIR}"/bin

# Install codesign shim
cp "${PACKAGE_DIR}"/codesign "${TARGET_DIR}"/bin

do_clean_bdir
