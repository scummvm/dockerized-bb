#! /bin/sh

REXX_VERSION=3.9.6

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch regina-rexx "https://sourceforge.net/projects/regina-rexx/files/regina-rexx/${REXX_VERSION}/regina-rexx-${REXX_VERSION}.tar.gz/download" 'tar xzf'

./configure --prefix="${CROSS_PREFIX}"

# Force using 1 job at a time as Makefile seems to not handle parallelism
do_make -j1
do_make -j1 install

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
