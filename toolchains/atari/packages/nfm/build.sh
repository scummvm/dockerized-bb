#! /bin/sh

NFM_VERSION=0.4.0
PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

case "${TARGET}" in
	m68020-60) cpu=68020-60 ;;
	*) error "nFM: unsupported target ${TARGET}" ;;
esac

do_make_bdir

do_http_fetch nfm "https://framagit.org/nokturnal/nfm/-/archive/${NFM_VERSION}/nfm-${NFM_VERSION}.tar.gz" 'tar xf'

# nFM calls the target AtariTOS, atari.platform calls it FreeMiNT
grep -rlZ --include=CMakeLists.txt --include='*.cmake' AtariTOS . | \
	xargs -0 sed -i 's/AtariTOS/FreeMiNT/g; s/CMAKE_C_STANDARD 17/CMAKE_C_STANDARD 11/; s/-std=c17/-std=c11/'

# FMST doesn't compile: OT_OPN and CO_YM2203 are undefined
# Libraries are installed into lib/m68020-60 by nFM itself
do_cmake \
	-DCMAKE_MODULE_PATH="$(pwd)/cmake.inc/modules" \
	-DCMAKE_ASM_VASM_COMPILER=${ATARI_TOOLCHAIN}/bin/vasmm68k_mot \
	-DCMAKE_ASM_VASM_COMPILER_ELF=TRUE \
	-DCMAKE_BUILD_TYPE=Final \
	-DM68K_CPU=${cpu} \
	-DTOS_CRT=stdlib \
	-DNFM_ENABLE_DRIVER_NOKTURNFM=ON \
	-DNFM_ENABLE_DRIVER_SB=ON \
	-DNFM_ENABLE_DRIVER_NULL=ON \
	-DNFM_ENABLE_DRIVER_NULL_NATFEATS_EXTENSION=ON \
	-DNFM_ENABLE_DRIVER_OPLL=ON \
	-DNFM_ENABLE_DRIVER_RW_OPL3_EXPRESS=ON \
	-DNFM_ENABLE_DRIVER_OPL3DUO=ON \
	-DNFM_ENABLE_DRIVER_OPLXLPT=ON \
	-DNFM_ENABLE_DRIVER_NUKED_OPL3=OFF \
	-DNFM_ENABLE_DRIVER_FMST=OFF \
	-DCMAKE_INSTALL_LIBDIR=lib \
	-DCMAKE_INSTALL_INCLUDEDIR=include/nfm
do_make nfm iofs allocators sysaudio
cmake --install . --component libraries
cmake --install . --component headers
cmake --install . --component Unspecified

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
