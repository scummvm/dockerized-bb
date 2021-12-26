#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

mkdir -p "$PSPDEV/share"
cp -as "/usr/share/automake"*/ "$PSPDEV/share/automake"

# Override config.sub to add psp detection
cp --remove-destination "$PACKAGE_DIR/config.sub" "$PSPDEV/share/automake"

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
