m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

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
		python-is-python3 \
		subversion \
		wget \
		zlib1g-dev \
		libtool-bin \
		python3-dev \
		bzip2 \
		libgmp-dev \
		pkg-config \
		ca-certificates \
		g++ \
		libssl-dev \
		xz-utils && \
	rm -rf /var/lib/apt/lists/*

ENV PS3DEV=/usr/local/ps3dev
ENV PSL1GHT=$PS3DEV

local_package(toolchain)

local_package(sdl_psl1ght)

# Define everything now because toolchain and sdl_psl1ght handle everything themselves already
ENV HOST=powerpc64-ps3-elf PREFIX=$PS3DEV/portlibs/ppu

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PS3DEV}/ppu/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PS3DEV}/ppu/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PS3DEV}/ppu/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${PS3DEV}/bin:${PS3DEV}/ppu/bin:${PS3DEV}/spu/bin:${PS3DEV}/portlibs/ppu/bin

helpers_package(giflib)

helpers_package(mpeg2dec)

helpers_package(a52dec)

helpers_package(fribidi)
