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

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		gcc \
		make \
		texinfo \
		patch \
		wget \
		zlib1g-dev \
		ca-certificates \
		libucl-dev && \
	rm -rf /var/lib/apt/lists/*

ENV PS2DEV=/usr/local/ps2dev
ENV PS2SDK=$PS2DEV/ps2sdk \
	GSKIT=$PS2DEV/gsKit

local_package(toolchain)

# Define everything now because toolchain and sdl_psl1ght handle everything themselves already
ENV HOST=ps2 PREFIX=$PS2SDK/ports

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PS2DEV}/ee/bin/ee-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PS2DEV}/ee/bin/ee-', `gcc, cpp, c++') \
	CC=${PS2DEV}/ee/bin/ee-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${PS2DEV}/bin:${PS2DEV}/ee/bin:${PS2DEV}/dvp/bin:${PS2DEV}/iop/bin:${PS2SDK}/bin:${PS2SDK}/ports/bin

ENV \
	CPPFLAGS="-isystem${PS2SDK}/ee/include -isystem${PS2SDK}/common/include -isystem${PREFIX}/include -isystem${PS2DEV}/isjpcm/include" \
	LDFLAGS="-L${PS2SDK}/ee/lib -L${PREFIX}/lib -L${PS2DEV}/isjpcm/lib"

local_package(isjpcm)

# Provides zlib, libpng, libjpeg, freetype
local_package(ps2sdk-ports)

#helpers_package(faad2)

local_package(libogg)

local_package(libtremor)

#helpers_package(libtheora)

#helpers_package(mpeg2dec)

#helpers_package(a52dec)

# No iconv

# No openssl nor curl

# No fribidi

# No fluidsynth
