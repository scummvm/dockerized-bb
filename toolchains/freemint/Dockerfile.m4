m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

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
		texinfo && \
	rm -rf /var/lib/apt/lists/*

ENV HOST=m68k-atari-mint

local_package(toolchain)

ENV INSTALL_DIR=/root/gnu-tools/m68000 \
	PREFIX=/root/gnu-tools/m68000/$HOST/sys-root/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${HOST}-', `gcc, cpp, c++') \
	CC=${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${INSTALL_DIR}/bin:${PREFIX}/bin

# TODO: Build m68020-60 and m5475 libraries

helpers_package(zlib)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo, -DCMAKE_SYSTEM_NAME=Generic -DCMAKE_SYSTEM_PROCESSOR=m68k -DWITH_SIMD=OFF)

helpers_package(giflib,,CFLAGS="${CFLAGS} -fno-PIC")

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libvorbis)

helpers_package(libvorbisidec)

helpers_package(libtheora)

helpers_package(flac, --with-pic=no)

helpers_package(faad2)

# rgb.c:46:22: error: alignment of 'dither' is greater than maximum object file alignment 2
# helpers_package(mpeg2dec)

helpers_package(a52dec)

# TODO: openssl and curl

# fluidsynth is unlikely to be fast enough.

helpers_package(freetype)

helpers_package(fribidi)

# TODO: GEM, LDG and pth, for SDL

# COPY packages/libsdl1.2 lib-helpers/packages/libsdl1.2/
helpers_package(libsdl1.2, --disable-video-opengl --disable-threads)

helpers_package(sdl-net1.2)
