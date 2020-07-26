#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..

# Don't load functions-platform.sh as it's not needed
NO_FUNCTIONS_PLATFORM=yes

. $HELPERS_DIR/functions-sdk.sh
. $HELPERS_DIR/functions.sh

do_make_bdir

do_install_sdk_tools

mkdir -p "${ANDROID_SDK_ROOT}"

# Install licences outside the build tree
do_sdk_accept_licenses "${ANDROID_SDK_ROOT}"

if [ -n "${ANDROID_SDK_VERSION}" ]; then
	do_sdk_install "platforms;android-${ANDROID_SDK_VERSION}"
	do_sdk_install "platform-tools"
fi
if [ -n "${ANDROID_BUILD_TOOLS_VERSION}" ]; then
	do_sdk_install "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"
fi

do_clean_bdir
