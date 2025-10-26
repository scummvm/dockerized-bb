#! /bin/sh

# This package is only for standalone toolchains of NDK

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch openssl

case $TARGET in
	arm-linux-androideabi) ssl_target=android-arm ;;
	aarch64-linux-android) ssl_target=android-arm64 ;;
	i686-linux-android) ssl_target=android-x86 ;;
	x86_64-linux-android) ssl_target=android-x86_64 ;;
	*) error "Unknown target ${TARGET}" ;;
esac

# Configure script expects these values and not absolute paths
export CC=clang
export AR=ar
export RANLIB=ranlib

if [ "$API" = "." ]; then
	# Standalone toolchain (even if merged)
	and_api=
	export ANDROID_NDK_ROOT=$TOOLCHAIN
else
	# Android fully unified toolchain
	and_api="-U__ANDROID_API__ -D__ANDROID_API__=$API"
fi

./Configure $ssl_target no-shared no-threads $and_api --prefix=${PREFIX} --libdir=${PREFIX}/lib/${TARGET}/${API}
do_make build_libs
do_make install_dev

do_clean_bdir
