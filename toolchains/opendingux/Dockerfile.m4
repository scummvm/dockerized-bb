m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY functions-platform.sh lib-helpers/

# Create fake links because those got deleted when installing gawk
# Using docker in an unprivileged container prevents deleting files across layers
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bison \
		flex \
		gawk \
		gperf \
		g++ \
		help2man \
		libncurses-dev \
		libtool-bin \
		texinfo && \
	ln -s /nonexistent /etc/alternatives/awk.1.gz && \
	ln -s /nonexistent /etc/alternatives/nawk.1.gz && \
	rm -rf /var/lib/apt/lists/*

ENV DINGUX_TOOLCHAIN=/opt/dingux-toolchain HOST=mipsel-unknown-linux-uclibc

local_package(toolchain)

ENV PREFIX=${DINGUX_TOOLCHAIN}/${HOST}/sysroot/usr

# Use buildroot CFLAGS
ENV \
	def_binaries(`${DINGUX_TOOLCHAIN}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DINGUX_TOOLCHAIN}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DINGUX_TOOLCHAIN}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin \
	CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
	CFLAGS="-march=mips32r2 -mtune=mips32r2 -mabi=32 -msoft-float -O2 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
	CXXFLAGS="-march=mips32r2 -mtune=mips32r2 -mabi=32 -msoft-float -O2 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64"

# Use same version as official toolchain
local_package(zlib)

# Use same version as official toolchain
local_package(libpng)

# Use same version as official toolchain
local_package(libjpeg)

# No giflib in the original toolchain build ours statically
helpers_package(giflib)

# No libfaad2 in the original toolchain build ours statically
helpers_package(faad2)

# Use same version as official toolchain
local_package(libmad)

# Use same version as official toolchain
local_package(libogg)

# Use same version as official toolchain
local_package(libtheora)

# Use same version as official toolchain
local_package(libvorbisidec)

# Use same version as official toolchain
local_package(flac)

# No mpeg2dec in the original toolchain build ours statically
helpers_package(mpeg2dec)

# No a52dec in the original toolchain build ours statically
helpers_package(a52dec)

# No libvpx in the original toolchain build ours statically
helpers_package(libvpx)

# Use same version as official toolchain
local_package(freetype)

# No fribidi in the original toolchain build ours statically
helpers_package(fribidi)

# Dependency of libsdl
# Use same version as official toolchain
local_package(alsa-lib)

# Dependency of libsdl
# Use same version as official toolchain
local_package(libiconv)

# Use same version as official toolchain
local_package(libsdl)

# Use same version as official toolchain
local_package(sdl-net1.2)

# TODO: openssl and curl

# fluidsynth is unlikely to be fast enough.
