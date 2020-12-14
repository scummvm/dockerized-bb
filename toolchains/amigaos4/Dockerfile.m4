FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/
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
local_package(pthreads)
local_package(librtmp)

local_package(libcurl)

local_package(libfreetype)

local_package(libfribidi)

local_package(libsdl2)

local_package(libsdl2_net)

# No fluidsynth
