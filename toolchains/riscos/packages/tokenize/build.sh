#! /bin/sh

TOKENIZE_VERSION=c7ed0290df0451724818267c9ceb7d8efde7f3ea

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch tokenize 'https://github.com/steve-fryatt/tokenize.git' "$TOKENIZE_VERSION"

do_make buildlinux/tokenize

mkdir -p "$GCCSDK_INSTALL_CROSSBIN"
cp buildlinux/tokenize "$GCCSDK_INSTALL_CROSSBIN"

do_clean_bdir
