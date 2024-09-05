#! /bin/sh

CCTOOLS_PORT_VERSION=942b4fcf3c5dc0770d89b64fb33903123a1c92aa
export LDID_VERSION=4bf8f4d60384a0693dbbe2084ce62a35bfeb87ab

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch cctools-port "https://github.com/tpoechtrager/cctools-port.git" "${CCTOOLS_PORT_VERSION}"

if [ "$1" = "iphone" ]; then
	TARGETDIR="${TARGET_DIR}" \
	TRIPLE=aarch64-apple-darwin11 \
		./usage_examples/ios_toolchain/build.sh "${SDK_DIR}/"* arm64
elif [ "$1" = "tv" ]; then
	# Create an appletv wrapper out of blue
	mv usage_examples/ios_toolchain usage_examples/tvos_toolchain
	for f in usage_examples/tvos_toolchain/*; do
		sed -i -e 's/iPhoneOS/AppleTVOS/g' "$f"
		sed -i -e 's/IPHONEOS_/TVOS_/g' "$f"
		sed -i -e 's/IOS_/TVOS_/g' "$f"
		sed -i -e 's/iphoneos-/tvos-/g' "$f"
	done

	TARGETDIR="${TARGET_DIR}" \
	TRIPLE=aarch64-apple-darwin11 \
		./usage_examples/tvos_toolchain/build.sh "${SDK_DIR}/"* arm64
else
	echo "ERROR: Invalid platform specified"
	exit 1
fi


# Create symlinks to arm64 as official Apple tools are named like this
for f in "${TARGET_DIR}"/bin/aarch64-apple-darwin11-*; do
	ln -s "$(basename "$f")" "$(echo "$f" | sed -e 's|/aarch64-|/arm64-|')"
done

# Install codesign shim
cp "${PACKAGE_DIR}"/codesign "${TARGET_DIR}"/bin

do_clean_bdir
