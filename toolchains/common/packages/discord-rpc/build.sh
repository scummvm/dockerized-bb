#! /bin/sh

DISCORD_RPC_VERSION=3.4.0

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch discord-rpc \
	"https://github.com/discord/discord-rpc/archive/v${DISCORD_RPC_VERSION}.tar.gz" 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Darwin for MacOS X

do_cmake "$@"
do_make
do_make install

do_clean_bdir
