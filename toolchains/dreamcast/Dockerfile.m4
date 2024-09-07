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
		pike8.0 \
		texinfo \
		xz-utils && \
	rm -rf /var/lib/apt/lists/*

ENV DCTOOLCHAIN=/opt/toolchains/dc

local_package(toolchain-sh4)

local_package(toolchain-arm)

local_package(makeip)

local_package(scramble)

local_package(libronin)

ENV HOST=sh-elf
ENV PREFIX=$DCTOOLCHAIN/sh-elf/${HOST}

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DCTOOLCHAIN}/sh-elf/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DCTOOLCHAIN}/sh-elf/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DCTOOLCHAIN}/sh-elf/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${DCTOOLCHAIN}/bin:${DCTOOLCHAIN}/sh-elf/bin:${DCTOOLCHAIN}/arm-eabi/bin \
	RONINDIR=${DCTOOLCHAIN}/ronin \
	IP_TEMPLATE_FILE=${DCTOOLCHAIN}/share/makeip/IP.TMPL

# The number of extra libraries should be kept to a minimum due to RAM limitations

# zlib is already installed in original toolchain

helpers_package(libmad)

define_aliases(dreamcast, dcdist, --enable-plugins --default-dynamic --enable-vkeybd)
