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
		lhasa \
		libgmp-dev \
		libmpc-dev \
		libmpfr-dev \
		python \
		texinfo && \
	rm -rf /var/lib/apt/lists/*

ENV CROSS_PREFIX=/usr/local/amigaos4 HOST=ppc-amigaos
ENV PREFIX=$CROSS_PREFIX/$HOST

local_package(toolchain)

# Build regina-rexx interpreter as Debian removed it
local_package(regina-rexx)

# Install various wrappers
local_package(amiga-shims)

# These symlinks are here for Ext_Inst_so.rexx which uses readelf and gcc commands without architecture prefix
RUN ln -s ${CROSS_PREFIX}/bin/${HOST}-gcc ${PREFIX}/bin/gcc
RUN ln -s ${CROSS_PREFIX}/bin/${HOST}-readelf ${PREFIX}/bin/readelf

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${CROSS_PREFIX}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${CROSS_PREFIX}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${CROSS_PREFIX}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${CROSS_PREFIX}/bin:${PREFIX}/bin \
	LDFLAGS="-athread=native"

local_package(zlib)

local_package(libpng)

local_package(libjpeg)

local_package(giflib)

#helpers_package(faad2)

local_package(libmad)

local_package(libogg)

local_package(libtheora)

local_package(libvorbis)

local_package(libflac)

local_package(libmpeg2)

local_package(liba52)

local_package(codesets)

local_package(libopenssl)

# Needed by precompiled libcurl
local_package(librtmp)

local_package(libcurl)

local_package(libfreetype)

local_package(libfribidi)

local_package(minigl)

local_package(libsdl2)

local_package(libsdl2_net)

# No fluidsynth
