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

ENV N64SDK=/opt/toolchains/mips64-n64

local_package(toolchain-mips64)

# local_package(makeip)

# local_package(scramble)

local_package(hkz-libn64)

ENV HOST=mips64
ENV PREFIX=$N64SDK/mips64/${HOST}

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${N64SDK}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${N64SDK}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${N64SDK}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${N64SDK}/bin

# The number of extra libraries should be kept to a minimum due to RAM limitations

# TODO: zlib

# TODO: vorbis
