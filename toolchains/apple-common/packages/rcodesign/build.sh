#! /bin/sh

RCODESIGN_VERSION=0.29.0
RCODESIGN_CHECKSUM=sha256:dbe85cedd8ee4217b64e9a0e4c2aef92ab8bcaaa41f20bde99781ff02e600002

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch apple-codesign- \
	"https://github.com/indygreg/apple-platform-rs/releases/download/apple-codesign%2F${RCODESIGN_VERSION}/apple-codesign-${RCODESIGN_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
	'tar xzf' "${RCODESIGN_CHECKSUM}"


mkdir -p "${TARGET_DIR}"/bin
cp rcodesign "${TARGET_DIR}"/bin

# Install codesign shim
cp "${PACKAGE_DIR}"/codesign "${TARGET_DIR}"/bin

do_clean_bdir
