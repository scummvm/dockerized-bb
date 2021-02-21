#! /bin/sh

LIBRONIN_VERSION=0_6

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libronin "https://github.com/sega-dreamcast/libronin/archive/ronin_${LIBRONIN_VERSION}.tar.gz" 'tar xzf'

export PATH=$PATH:${DCTOOLCHAIN}/bin:${DCTOOLCHAIN}/sh-elf/bin:${DCTOOLCHAIN}/arm-eabi/bin

# Makefile doesn't handle well parallelism
do_make -j1 all

install -D -t ${DCTOOLCHAIN}/ronin/lib/ lib/libronin.a lib/libronin-noserial.a lib/crt0.o
install -D -t ${DCTOOLCHAIN}/ronin/include/ronin/ cdfs.h common.h \
	dc_time.h gddrive.h gfxhelper.h gtext.h maple.h matrix.h misc.h notlibc.h report.h \
	ronin.h serial.h sincos_rroot.h soundcommon.h sound.h ta.h translate.h video.h vmsfs.h
install -D -t ${DCTOOLCHAIN}/ronin/ README COPYING

install -D -t ${DCTOOLCHAIN}/ronin/lib/ zlib/libz.a
install -D -t ${DCTOOLCHAIN}/ronin/include/ zlib/zlib.h zlib/zconf.h
install -D zlib/README ${DCTOOLCHAIN}/ronin/ZLIB_README

install -D -t ${DCTOOLCHAIN}/ronin/lib/ zlib/libz.a
install -D -t ${DCTOOLCHAIN}/ronin/include/ lwipopts.h
install -D -t ${DCTOOLCHAIN}/ronin/include/lwip/ lwip/include/lwip/*
install -D -t ${DCTOOLCHAIN}/ronin/include/netif/ lwip/include/netif/*
install -D -t ${DCTOOLCHAIN}/ronin/include/lwip/ lwip/include/ipv4/lwip/*
install -D -t ${DCTOOLCHAIN}/ronin/include/arch/ lwip/arch/dc/include/arch/*
install -D -t ${DCTOOLCHAIN}/ronin/include/netif/ lwip/arch/dc/include/netif/*
install -D lwip/COPYING ${DCTOOLCHAIN}/ronin/LWIP_COPYING

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
