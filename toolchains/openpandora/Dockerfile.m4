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

# Create fake links because those got deleted when installing gawk
# Using docker in an unprivileged container prevents deleting files across layers
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bison \
		flex \
		gawk \
		g++ \
		help2man \
		libncurses-dev \
		libtool-bin \
		texinfo && \
	ln -s /nonexistent /etc/alternatives/awk.1.gz && \
	ln -s /nonexistent /etc/alternatives/nawk.1.gz && \
	rm -rf /var/lib/apt/lists/*

ENV TOOLCHAIN=/opt/openpandora HOST=arm-angstrom-linux-gnueabi

local_package(toolchain)

ENV PREFIX=${TOOLCHAIN}/${HOST}/sysroot/usr

ENV \
	def_binaries(`${TOOLCHAIN}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${TOOLCHAIN}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${TOOLCHAIN}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin

# Use same version as official toolchain
local_package(zlib)

# Use same version as official toolchain
local_package(libpng)

# Use same version as official toolchain
local_package(libjpeg)

# Use same version as official toolchain
local_package(faad2)

# libmad hasn't seen any activity since a really long time and still has the same ABI
helpers_package(libmad, --enable-shared)

# Use same version as official toolchain
local_package(libogg)

# libtheora hasn't seen any activity since a really long time and still has the same version
helpers_package(libtheora, --enable-shared)

# Use same version as official toolchain
local_package(libvorbis)

# Use same version as official toolchain
local_package(flac)

# No mpeg2dec in the original toolchain build ours statically
helpers_package(mpeg2dec)

# No a52dec in the original toolchain build ours statically
helpers_package(a52dec)

# Use same version as official toolchain
local_package(freetype)

# No fribidi in the original toolchain build ours statically
helpers_package(fribidi)

# We try to have the same SDL_config.h by installing same dependencies

# Use same version as official toolchain
# Dependency of SDL
local_package(tslib)

# Use same version as official toolchain
# Dependency of SDL
local_package(x11)

# libGL could be needed but it seems toolchain got it built but not installed, so don't know...

# Use same version as official toolchain
# Dependency of SDL
local_package(alsa-lib)

# Use same version as official toolchain
local_package(libsdl)

# Use same version as official toolchain
local_package(sdl-net1.2)

# Use same version as official toolchain
local_package(gnutls)

# Use same version as official toolchain
local_package(curl)

# fluidsynth-lite is unlikely to be fast enough.
