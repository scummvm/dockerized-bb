#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..

# Don't load functions-platform.sh as it's not needed
NO_FUNCTIONS_PLATFORM=yes

. $HELPERS_DIR/functions-sdk.sh
. $HELPERS_DIR/functions.sh

do_make_bdir

do_install_sdk_tools

do_sdk_install "ndk;${ANDROID_NDK_VERSION}"

cd "ndk/${ANDROID_NDK_VERSION}"

# Don't cleanup as OpenSSL still need them
# Cleanup unused parts of the NDK (which will get removed in future versions)
#rm -rf platforms sources/cxx-stl sysroot
#for d in toolchains/*; do
#	if [ "$d" = "toolchains/llvm" ]; then
#		continue
#	fi
#	rm -rf "$d"
#done

mkdir -p "${ANDROID_NDK_ROOT}/"
# mv is faster than cp
mv ./* "${ANDROID_NDK_ROOT}/"

do_clean_bdir
