#! /bin/sh

# These versions are the ones Marcus uses
BINUTILS_VERSION=2.18
GCC_VERSION=4.9.4
NEWLIB_VERSION=1.19.0

# This package is inspired by dc-chain scripts for KallistiOS. Credits go to them.

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

target=sh-elf
prefix="${DCTOOLCHAIN}/${target}"
extra_options="--with-multilib-list=m4-single-only --with-endian=little --with-cpu=m4-single-only"

do_make_bdir

# Add our (to be built) tools to path
export PATH="${PATH}:${prefix}/bin"

# Binutils
do_http_fetch binutils "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2" 'tar xjf'

CFLAGS="-fcommon" CXXFLAGS="-fcommon" \
./configure --target=${target} --prefix="${prefix}" --disable-werror
do_make
do_make install

cd ..

# GCC...
do_http_fetch gcc "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2" 'tar xjf'

# Do off tree build
GCC_DIR=$(pwd)

cd ..

# ... stage 1
mkdir gcc-build-stage1
cd gcc-build-stage1

CFLAGS="-fcommon" CXXFLAGS="-fcommon --std=gnu++11" \
"${GCC_DIR}"/configure \
	--target=${target} \
	--prefix="${prefix}" \
	--without-headers \
	--with-newlib \
	--enable-languages=c \
	--disable-libssp \
	--disable-tls \
	--enable-checking=release \
	${extra_options}
do_make
do_make install-strip

cd ..

# Newlib
do_http_fetch newlib "ftp://sourceware.org/pub/newlib/newlib-${NEWLIB_VERSION}.tar.gz" 'tar xzf'

CC_FOR_TARGET="${DCTOOLCHAIN}/sh-elf/bin/sh-elf-gcc" ./configure \
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

CFLAGS="-fcommon" CXXFLAGS="-fcommon --std=gnu++11" \
"${GCC_DIR}"/configure \
	--target=${target} \
	--prefix="${prefix}" \
	--with-newlib \
	--disable-libssp \
	--disable-tls \
	--enable-languages=c,c++ \
	--enable-threads=single \
	--enable-checking=release \
	${extra_options}
do_make
do_make install-strip

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
