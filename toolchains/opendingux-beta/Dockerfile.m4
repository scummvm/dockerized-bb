m4_include(`paths.m4')m4_dnl
m4_define(`local_sdk_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`local_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`helpers_package', COPY --from=helpers /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY multi-build.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bc \
		ccache \
		cpio \
		g++ \
		g++-multilib \
		mercurial \
		rsync \
		u-boot-tools && \
	rm -rf /var/lib/apt/lists/*

ENV OPENDINGUX_ROOT=/opt/opendingux

local_sdk_package(toolchain)

# zlib is already installed in original toolchain

# libpng is already installed in original toolchain

# libjpeg is already installed in original toolchain

helpers_package(giflib)

# libmad is already installed in original toolchain

# libogg is already installed in original toolchain

# libvorbis is already installed in original toolchain

# libvorbisidec is already installed in original toolchain

# libtheora is already installed in original toolchain

# flac is already installed in original toolchain

# libmikmod is already installed in original toolchain

helpers_package(faad2)

helpers_package(mpeg2dec)

helpers_package(a52dec)

helpers_package(libmpcdec)

helpers_package(libvpx)

# No curl support in configure

# freetype is already installed in original toolchain

helpers_package(fribidi)

# sdl2 is already installed in original toolchain

# sdl2_net is already installed in original toolchain

# fluidsynth is already installed in original toolchain
m4_define(`define_od_aliases', `define_aliases(
opendingux-$1, od-make-opk, , \
CXX=${OPENDINGUX_ROOT}/$1-toolchain/bin/mipsel-linux-c++ \
PKG_CONFIG_LIBDIR=${OPENDINGUX_ROOT}/$1-toolchain/mipsel-$1-linux-$2/sysroot/usr/lib/pkgconfig \
PKG_CONFIG_SYSROOT_DIR=${OPENDINGUX_ROOT}/$1-toolchain/mipsel-$1-linux-$2/sysroot \
PATH=$PATH:${OPENDINGUX_ROOT}/$1-toolchain/mipsel-$1-linux-$2/sysroot/usr/bin:${OPENDINGUX_ROOT}/$1-toolchain/bin, $1)')m4_dnl
define_od_aliases(gcw0, uclibc)
define_od_aliases(lepus, musl)
define_od_aliases(rs90, musl)
