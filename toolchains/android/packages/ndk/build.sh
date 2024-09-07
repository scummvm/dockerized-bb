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

# Cleanup unused parts of the NDK
rm -rf prebuilt sources/cxx-stl sources/third_party simpleperf shader-tools toolchains/renderscript

mkdir -p "${ANDROID_NDK_ROOT}/"
# mv is faster than cp
mv ./* "${ANDROID_NDK_ROOT}/"

do_clean_bdir
