FROM toolchains/common AS helpers

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

ENV PS3DEV=/usr/local/ps3dev
ENV PSL1GHT=$PS3DEV

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bison \
		flex \
		gcc \
		libelf-dev \
		make \
		texinfo \
		libncurses5-dev \
		patch \
		python \
		subversion \
		wget \
		zlib1g-dev \
		libtool-bin \
		python-dev \
		bzip2 \
		libgmp-dev \
		pkg-config \
		ca-certificates \
		g++ \
		libssl-dev \
		xz-utils && \
	rm -rf /var/lib/apt/lists/*

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

local_package(toolchain)

local_package(sdl_psl1ght)

# Define everything at the end because toolchain and sdl_psl1ght handle everything themselves already
ENV HOST=powerpc64-ps3-elf PREFIX=$PS3DEV/ppu
ENV \
	ACLOCAL_PATH=$PS3DEV/portlibs/ppu/share/aclocal \
	PKG_CONFIG_LIBDIR=$PS3DEV/portlibs/ppu/lib \
	PKG_CONFIG_PATH=$PS3DEV/portlibs/ppu/lib/pkgconfig \
	CC=$PREFIX/bin/$HOST-gcc \
	CPP=$PREFIX/bin/$HOST-cpp \
	CXX=$PREFIX/bin/$HOST-c++ \
	AR=$PREFIX/bin/$HOST-ar \
	AS=$PREFIX/bin/$HOST-as \
	CXXFILT=$PREFIX/bin/$HOST-c++filt \
	LD=$PREFIX/bin/$HOST-ld \
	RANLIB=$PREFIX/bin/$HOST-ranlib \
	STRIP=$PREFIX/bin/$HOST-strip \
	STRINGS=$PREFIX/bin/$HOST-strings

helpers_package(mpeg2dec)

helpers_package(a52dec)
