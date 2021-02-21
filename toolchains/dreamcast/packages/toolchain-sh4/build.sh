#! /bin/sh

BINUTILS_VERSION=2.34
GCC_VERSION=9.3.0
NEWLIB_VERSION=3.3.0

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
do_http_fetch binutils "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz" 'tar xJf'

# We need to patch ld script because new GCC versions put stuff in .text.unlikely which is emitted first
# When TEXT_START_SYMBOLS is defined, it is placed first in .text section: we place here the whole text section of crt0.o (used by libronin)
sed -i -e '$a TEXT_START_SYMBOLS="*crt0.o(.text)"' ld/emulparams/shelf.sh

./configure --target=${target} --prefix="${prefix}" --disable-werror
do_make
do_make install

cd ..

# GCC...
do_http_fetch gcc "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz" 'tar xJf'

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
