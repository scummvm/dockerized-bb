m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

FROM toolchains/common AS helpers

FROM toolchains/devkitarm

# For bannertool
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++ \
		zip && \
	rm -rf /var/lib/apt/lists/*

# We need to compile tools before setting environment for all other packages
# We do this now
local_package(bannertool)

local_package(Project_CTR)

ENV PREFIX=${DEVKITPRO}/portlibs/3ds HOST=arm-none-eabi

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITARM}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITARM}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITARM}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/3ds/bin

# From pkgbuild-scripts/3dsvars.sh
ENV \
	CFLAGS="-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft -O2 -mword-relocations -ffunction-sections -fdata-sections" \
	CXXFLAGS="-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft -O2 -mword-relocations -ffunction-sections -fdata-sections" \
	CPPFLAGS="-D_3DS -I${PREFIX}/include -I${DEVKITPRO}/libctru/include" \
	LDFLAGS="-L${PREFIX}/lib -L${DEVKITPRO}/libctru/lib" \
	LIBS="-lctru"

# zlib is already installed in original toolchain

# libpng is already installed in original toolchain

# libjpeg-turbo is already installed in original toolchain

helpers_package(giflib)

helpers_package(faad2)

# libmad is already installed in original toolchain

# libogg is already installed in original toolchain

# libtheora is already installed in original toolchain

# libvorbisidec is already installed in original toolchain

# flac is already installed in original toolchain

helpers_package(mpeg2dec)

helpers_package(a52dec)

# curl is already installed in original toolchain

# freetype is already installed in original toolchain

helpers_package(fribidi)

# No fluidsynth
