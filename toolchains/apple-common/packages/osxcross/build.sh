#! /bin/sh

OSXCROSS_VERSION=e6ab3fa7423f9235ce9ed6381d6d3af191b46b59
export XAR_VERSION=5fa4675419cfec60ac19a9c7f7c2d0e7c831a497
export LIBDISPATCH_VERSION=323b9b4e0ca05d6c56a0c2f2d7d8d47363e612b7

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch osxcross "https://github.com/tpoechtrager/osxcross.git" "${OSXCROSS_VERSION}"

# Link SDK tarballs
for f in "${SDK_DIR}"/*; do
	ln -s "$f" tarballs/
done

# This will let build.sh use our own clang
export PATH=$PATH:${TARGET_DIR}/bin

# Don't ask anything
UNATTENDED=1 ./build.sh

# Prevent installation
sed -i -e '/mkdir -p \${CLANG_INCLUDE_DIR}/,+1d' ./build_compiler_rt.sh

./build_compiler_rt.sh

BDIR=$PWD/build

# Copy to built files to our place
mkdir -p ${TARGET_DIR}/compiler_rt/include ${TARGET_DIR}/compiler_rt/lib/darwin
cp -rv $BDIR/compiler-rt/compiler-rt/include/sanitizer ${TARGET_DIR}/compiler_rt/include/
cp -v  $BDIR/compiler-rt/compiler-rt/build/lib/darwin/*.a ${TARGET_DIR}/compiler_rt/lib/darwin/
cp -v  $BDIR/compiler-rt/compiler-rt/build/lib/darwin/*.dylib ${TARGET_DIR}/compiler_rt/lib/darwin/

# Now install manually by linking
CLANG_LIB_DIR=$(clang -print-search-dirs | grep "libraries: =" | \
	                tr '=' ' ' | tr ':' ' ' | awk '{print $2}')
CLANG_INCLUDE_DIR="${CLANG_LIB_DIR}/include"
CLANG_DARWIN_LIB_DIR="${CLANG_LIB_DIR}/lib/darwin"

# Don't install includes, they are already here
mkdir -p "$(dirname "${CLANG_DARWIN_LIB_DIR}")"
ln -s ${TARGET_DIR}/compiler_rt/lib/darwin ${CLANG_DARWIN_LIB_DIR}

find /tmp -mindepth 1 -delete

do_clean_bdir
