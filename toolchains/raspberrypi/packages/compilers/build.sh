#! /bin/sh

DIST_VERSION=Bullseye
# Use same version as Raspbian one
GCC_VERSION=10.2.0
# Which RPI to target, RPI and SUFFIX must match
RPI="1%2C%20Zero"
SUFFIX="0-1"

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

base_url="https://downloads.sourceforge.net/project/raspberry-pi-cross-compilers/Raspberry%20Pi%20GCC%20Cross-Compiler%20Toolchains"
do_http_fetch cross-pi-gcc \
	"${base_url}/${DIST_VERSION}/GCC%20${GCC_VERSION}/Raspberry%20Pi%20${RPI}/cross-gcc-${GCC_VERSION}-pi_${SUFFIX}.tar.gz" \
	"tar xzf"

# Move everything in a fixed location to ease version change
mkdir -p "$RPI_HOME/"
mv * "$RPI_HOME/"

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
