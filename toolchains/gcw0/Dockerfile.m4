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
		python-libxml2 \
		texinfo && \
	ln -s /nonexistent /etc/alternatives/awk.1.gz && \
	ln -s /nonexistent /etc/alternatives/nawk.1.gz && \
	rm -rf /var/lib/apt/lists/*

ENV GCW_TOOLCHAIN=/opt/gcw0-toolchain HOST=mipsel-gcw0-linux-uclibc

local_package(toolchain)

ENV PREFIX=${GCW_TOOLCHAIN}/${HOST}/sysroot/usr

ENV \
	def_binaries(`${GCW_TOOLCHAIN}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${GCW_TOOLCHAIN}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${GCW_TOOLCHAIN}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin

# Use same version as official toolchain
local_package(zlib)

# Use same version as official toolchain
local_package(libpng)

# Use same version as official toolchain
local_package(libjpeg)

# No libfaad2 in the original toolchain build ours statically
helpers_package(faad2)

# No libmad in the original toolchain build ours statically
helpers_package(libmad)

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

# Use same version as official toolchain
local_package(freetype)

# No fribidi in the original toolchain build ours statically
helpers_package(fribidi)

# Dependency of mesa3d
# Use same version as official toolchain
local_package(libdrm)

# Dependency of mesa3d
# Use same version as official toolchain
local_package(expat)

# Dependency of mesa3d
# Use same version as official toolchain
local_package(etna_viv)

# Dependency of libsdl for GLES
# Use same version as official toolchain
local_package(mesa3d-etna_viv)

# Dependency of libsdl
# Use same version as official toolchain
local_package(alsa-lib)

# Dependency of libsdl
# Use same version as official toolchain
local_package(libiconv)

# Dependency of libsdl
# Use same version as official toolchain
local_package(eudev)

# Use same version as official toolchain
local_package(libsdl2)

# Use same version as official toolchain
local_package(sdl2-net)

# Use same version as official toolchain
local_package(libsdl)

# Use same version as official toolchain
local_package(sdl-net1.2)

# TODO: openssl and curl

# fluidsynth-lite is unlikely to be fast enough.
