#! /bin/sh

TOKENIZE_VERSION=596792257a9f2964c014b60c15c4ce012f4cf203

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_git_fetch tokenize 'https://github.com/steve-fryatt/tokenize.git' "$TOKENIZE_VERSION"

do_make obj buildlinux/tokenize
cp buildlinux/tokenize /usr/local/bin/

do_clean_bdir
