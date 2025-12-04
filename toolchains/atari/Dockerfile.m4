m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY functions-platform.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bison \
		flex \
		gcc \
		g++ \
		libgmp-dev \
		libisl-dev \
		libmpc-dev \
		libmpfr-dev \
		patch \
		subversion \
		texinfo && \
	rm -rf /var/lib/apt/lists/*

ENV ATARITOOLCHAIN=/opt/toolchains/atari

local_package(toolchain)

ENV HOST=m68k-atari-mintelf
ENV PREFIX=$ATARITOOLCHAIN/$HOST/sys-root/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${HOST}-', `gcc, cpp, c++') \
	CC=${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	PATH=$PATH:${ATARITOOLCHAIN}/bin
# Disable because it doesn't support multilib
#	def_pkg_config(`${PREFIX}')

COPY m68k-atari-mintelf-pkg-config ${ATARITOOLCHAIN}/bin

local_package(gemlib)
local_package(ldg)
local_package(usound)

helpers_package(zlib, --libdir=${PREFIX}/lib/m68020-60, CFLAGS="-O2 -fomit-frame-pointer -m68020-60")

helpers_package(zlib, --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(libpng1.6, --bindir=${PREFIX}/bin/m5475 --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(libjpeg-turbo, -DCMAKE_SYSTEM_NAME=Generic -DCMAKE_SYSTEM_PROCESSOR=m68k -DWITH_SIMD=OFF -DCMAKE_INSTALL_BINDIR=${PREFIX}/bin/m5475 -DCMAKE_INSTALL_LIBDIR=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(giflib,, CFLAGS="-fno-PIC -O2 -fomit-frame-pointer -mcpu=5475" LIBDIR=${PREFIX}/lib/m5475)
helpers_package(libmad, --enable-speed --bindir=${PREFIX}/bin/m5475 --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(libogg, --bindir=${PREFIX}/bin/m5475 --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(libmikmod, --bindir=${PREFIX}/bin/m5475 --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(libvorbis, --bindir=${PREFIX}/bin/m5475 --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(libtheora, --bindir=${PREFIX}/bin/m5475 --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(freetype, --bindir=${PREFIX}/bin/m5475 --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
helpers_package(libsdl1.2, --disable-video-opengl --disable-threads --bindir=${PREFIX}/bin/m5475 --libdir=${PREFIX}/lib/m5475, CFLAGS="-O2 -fomit-frame-pointer -mcpu=5475")
