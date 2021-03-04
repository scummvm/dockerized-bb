#! /bin/sh

# Stick with toolchain version
ETNA_VIV_VERSION=4aefe679119bacc14e70ead920273675cab31c92

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch etna_viv "https://github.com/laanwj/etna_viv/archive/${ETNA_VIV_VERSION}.tar.gz" 'tar xzf'

do_make -C src/etnaviv \
	GCCPREFIX="${GCC%gcc}" \
	PLATFORM_CFLAGS="-D_POSIX_C_SOURCE=200809 -D_GNU_SOURCE -DLINUX" \
	PLATFORM_CXXFLAGS="-D_POSIX_C_SOURCE=200809 -D_GNU_SOURCE -DLINUX" \
	PLATFORM_LDFLAGS="-ldl -lpthread" \
	GCABI="v4_uapi" \
	ETNAVIV_PROFILER=1

cp src/etnaviv/libetnaviv.a "${PREFIX}"/lib
mkdir -p "${PREFIX}"/include/etnaviv
cp src/etnaviv/*.h "${PREFIX}"/include/etnaviv

do_clean_bdir
