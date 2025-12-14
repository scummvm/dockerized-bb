#! /bin/sh

BINUTILS_VERSION=2.42
GCC_VERSION=13.4.0
MINTLIB_VERSION=fba33c97fb2979edc0f9133ca54b133e1a66d707
FDLIBM_VERSION=46a0b20e7094cb2946be02f905a6bdea9933cf29
MINTBIN_VERSION=d595f7cfb6c51c4ed3a2c39d3d1c278d14a145a5

# This package is inspired by dc-chain scripts for KallistiOS. Credits go to them.

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

target=m68k-atari-mintelf
prefix="${ATARI_TOOLCHAIN}"

do_make_bdir

# Add our (to be built) tools to path
export PATH="${PATH}:${prefix}/bin"

# Binutils
do_http_fetch binutils "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz" 'tar xf'
do_patch binutils

./configure --target=${target} --prefix="${prefix}" --disable-nls --disable-werror --disable-gdb --disable-libdecnumber --disable-readline --disable-sim
do_make
do_make install

cd ..

# GCC...
do_http_fetch gcc "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz" 'tar xf'
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
	--with-sysroot="${prefix}/${target}/sysroot" \
	--disable-decimal-float \
	--disable-libgomp \
	--disable-libssp \
	--disable-libatomic \
	--disable-libquadmath \
	--disable-tls \
	--disable-libvtv \
	--disable-libstdcxx \
	--disable-lto \
	--disable-libcc1 \
	--disable-fixincludes \
	--enable-version-specific-runtime-libs
# libgcc is needed for mintlib's tools
do_make all-gcc all-target-libgcc
do_make install-gcc install-target-libgcc

cd ..

# MiNTLib
do_http_fetch mintlib "https://github.com/freemint/mintlib/archive/${MINTLIB_VERSION}.tar.gz" 'tar xf'
do_make CROSS_TOOL=${target} SHELL=/bin/bash DESTDIR=${prefix}/${target}/sysroot WITH_020_LIB=yes WITH_V4E_LIB=yes WITH_DEBUG_LIB=no
do_make CROSS_TOOL=${target} SHELL=/bin/bash DESTDIR=${prefix}/${target}/sysroot WITH_020_LIB=yes WITH_V4E_LIB=yes WITH_DEBUG_LIB=no install

# remove m68000 leftovers
rm -r ${prefix}/${target}/sysroot/sbin
rm -r ${prefix}/${target}/sysroot/usr/sbin

cd ..

# FDLIBM
do_http_fetch fdlibm "https://github.com/freemint/fdlibm/archive/${FDLIBM_VERSION}.tar.gz" 'tar xf'
./configure --host=${target} --prefix=/usr
do_make DESTDIR=${prefix}/${target}/sysroot
do_make DESTDIR=${prefix}/${target}/sysroot install

cd ..

# GCC...
# ... stage 2
mkdir gcc-build-stage2
cd gcc-build-stage2

CFLAGS_FOR_TARGET="-O2 -fomit-frame-pointer" CXXFLAGS_FOR_TARGET="-O2 -fomit-frame-pointer" \
"${GCC_DIR}"/configure \
	--target=${target} \
	--prefix="${prefix}" \
	--with-sysroot="${prefix}/${target}/sysroot" \
	--disable-nls \
	--enable-lto \
	--enable-languages="c,c++,lto" \
	--disable-libstdcxx-pch \
	--disable-threads \
	--disable-tls \
	--disable-libgomp \
	--disable-sjlj-exceptions \
	--with-libstdcxx-zoneinfo=no \
	--disable-libcc1 \
	--disable-fixincludes \
	--enable-version-specific-runtime-libs
do_make
do_make install-strip

cd ..

# MiNTBin
do_http_fetch mintbin "https://github.com/freemint/mintbin/archive/${MINTBIN_VERSION}.tar.gz" 'tar xf'
./configure --target=${target} --prefix="" --disable-nls
do_make DESTDIR=${prefix}
do_make DESTDIR=${prefix} install-strip

cd ..

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
