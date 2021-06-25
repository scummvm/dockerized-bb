#! /bin/sh

OSXCROSS_VERSION=447cf3b3ea4323d24648f5f7f775f5977a0d15bd
export PBZX_VERSION=2a4d7c3300c826d918def713a24d25c237c8ed53
export XAR_VERSION=2b9a4ab7003f1db8c54da4fea55fcbb424fdecb0

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch osxcross "https://github.com/tpoechtrager/osxcross.git" "${OSXCROSS_VERSION}"

# There is a bug in Debian Stretch docker package which prevents having too big files
# Split the file and join back it there
if [ "$(ls -1 "${PACKAGES_LOCATION}${PACKAGE}"* | wc -l)" -gt 1 ]; then
	XCODE_FILE=$(mktemp -up $(pwd))
	mkfifo -m 600 "$XCODE_FILE"
	cat "${PACKAGES_LOCATION}${PACKAGE}"* | USESYSTEMCOMPILER=yes CC=gcc ./tools/gen_sdk_package_pbzx.sh /dev/stdin
else
	XCODE_FILE=$(echo "${PACKAGES_LOCATION}${PACKAGE}"*)
	USESYSTEMCOMPILER=yes CC=gcc ./tools/gen_sdk_package_pbzx.sh "$XCODE_FILE"
fi

mkdir -p "${SDK_DIR}"
mv ./*.sdk.* "${SDK_DIR}"/

do_clean_bdir
