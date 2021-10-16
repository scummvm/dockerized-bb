#! /bin/sh

# These versions are the ones used on the old buildbot
BINUTILS_VERSION=2.19.1
GCC_VERSION=4.4.2
NEWLIB_VERSION=1.17.0

# This package is inspired by dc-chain scripts for KallistiOS. Credits go to them.

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

target=mips64
prefix="${N64SDK}"
extra_options="--disable-multilib --disable-__cxa_atexit"

do_make_bdir

# Add our (to be built) tools to path
export PATH="${PATH}:${prefix}/bin"

# Binutils
do_http_fetch binutils "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2" 'tar xjf'

./configure --target=${target} --prefix="${prefix}" --disable-werror
do_make
do_make install

cd ..

# GCC...
do_http_fetch gcc "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2" 'tar xjf'
do_patch gcc

# Do off tree build
GCC_DIR=$(pwd)

cd ..

# ... stage 1
mkdir gcc-build-stage1
cd gcc-build-stage1

"${GCC_DIR}"/configure \
	--target=${target} \
	--prefix="${prefix}" \
	--without-headers \
	--with-newlib \
	--enable-languages=c \
	--disable-shared \
	--disable-nls \
	--disable-threads \
	${extra_options}
do_make all-gcc
do_make install-gcc

cd ..

# Newlib
do_http_fetch newlib "ftp://sourceware.org/pub/newlib/newlib-${NEWLIB_VERSION}.tar.gz" 'tar xzf'

CC_FOR_TARGET="${prefix}/bin/${target}-gcc" ./configure \
	--target=${target} \
	--prefix="${prefix}" \
	${extra_options}
do_make
do_make install

cd ..

# GCC...
# ... stage 2
mkdir gcc-build-stage2
cd gcc-build-stage2

"${GCC_DIR}"/configure \
	--target=${target} \
	--prefix="${prefix}" \
	--with-newlib \
	--enable-languages=c,c++ \
	--disable-shared \
	--disable-nls \
	--disable-threads \
	${extra_options}
do_make
do_make install

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
