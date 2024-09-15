#! /bin/sh

RCODESIGN_VERSION=0.27.0
RCODESIGN_CHECKSUM=sha256:a0e0c548b313026abf4f40a6e06554d352c6f4e1add6a87d626c94134a4ee564

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
