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
		g++ \
		help2man \
		libncurses-dev \
		libtool-bin \
		texinfo && \
	ln -s /nonexistent /etc/alternatives/awk.1.gz && \
	ln -s /nonexistent /etc/alternatives/nawk.1.gz && \
	rm -rf /var/lib/apt/lists/*

ENV CAANOO=/opt/caanoo HOST=arm-gph-linux-gnueabi

local_package(toolchain)

ENV PREFIX=${CAANOO}/${HOST}/sysroot/usr

ENV \
	def_binaries(`${CAANOO}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${CAANOO}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${CAANOO}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin

# Use same version as official toolchain
local_package(zlib)

# Use same version as official toolchain
local_package(libpng)

local_package(libjpeg)

# No giflib in the original toolchain build ours statically
helpers_package(giflib)

# No libfaad2 in the original toolchain build ours statically
helpers_package(faad2)

# libmad hasn't seen any activity since a really long time and still has the same ABI
helpers_package(libmad, --enable-shared)

# Use same version as official toolchain
local_package(libogg)

# No theora in the original toolchain build ours statically but fix build with our old libogg
COPY packages/libtheora lib-helpers/packages/libtheora/
helpers_package(libtheora, --disable-asflag-probe)

# libvorbisidec in the original toolchain/firmware is too old for us, build ours statically
helpers_package(libvorbisidec)

# No FLAC in the original toolchain build ours statically
helpers_package(flac)

# No libmikmod in the original toolchain build ours statically
helpers_package(libmikmod)

# No mpeg2dec in the original toolchain build ours statically
helpers_package(mpeg2dec)

# No a52dec in the original toolchain build ours statically
helpers_package(a52dec)

# No libmpcdec in the original toolchain build ours statically
helpers_package(libmpcdec)

# No libvpx in the original toolchain build ours statically
helpers_package(libvpx)

# Use same version as official toolchain
local_package(freetype)

# No fribidi in the original toolchain build ours statically
helpers_package(fribidi)

# Use same version as official toolchain
# Dependency of patched SDL
local_package(tslib)

# Use patched version from OpenHandheld
local_package(libsdl)

# Use same version as official toolchain
local_package(sdl-net1.2)

# TODO: openssl and curl

# fluidsynth is unlikely to be fast enough.

define_aliases(caanoo, caanoo-bundle, --enable-plugins --default-dynamic --enable-vkeybd)
