m4_define(`DEVKITPPC_VERSION',20210619)
# This version of devkitPPC depends on a Debian Stretch
# For now it works with stable-slim, we will have to ensure it stays like that
FROM devkitpro/devkitppc:DEVKITPPC_VERSION AS original-toolchain

m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		curl \
		gnupg \
		libxml2 \
		make \
		pkg-config \
		xz-utils \
		&& \
	rm -rf /var/lib/apt/lists/*

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITPPC=${DEVKITPRO}/devkitPPC

# Copy PPC toolchain
COPY --from=original-toolchain ${DEVKITPRO}/ ${DEVKITPRO}

local_package(libgxflux)

# Define everything only now as libgxflux already handles all of this

ENV PREFIX=${DEVKITPRO}/portlibs/ppc HOST=powerpc-eabi

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITPPC}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITPPC}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITPPC}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/ppc/bin

# From pkgbuild-scripts/ppcvars.sh
ENV \
	CFLAGS="-O2 -mcpu=750 -meabi -mhard-float -ffunction-sections -fdata-sections" \
	CXXFLAGS="-O2 -mcpu=750 -meabi -mhard-float -ffunction-sections -fdata-sections" \
	CPPFLAGS="-I${PREFIX}/include" \
	LDFLAGS="-L${PREFIX}/lib"

# zlib is already installed in original toolchain

# libpng is already installed in original-toolchain

# libjpeg-turbo is already installed in original-toolchain

helpers_package(giflib)

helpers_package(faad2)

# libmad is already installed in original-toolchain

# libogg is already installed in original-toolchain

helpers_package(libtheora)

# libvorbis is already installed in original-toolchain

# Disable AltiVec as it's not supported by targets and SSE2 because configure script enables it
# Copy specific patch to disable FORTIFY as toolchain doesn't seem to support it
COPY packages/flac lib-helpers/packages/flac
helpers_package(flac, --disable-altivec)

helpers_package(mpeg2dec, , CFLAGS="$CFLAGS -mno-altivec")

helpers_package(a52dec)

# curl

# freetype is already installed in original-toolchain

helpers_package(fribidi)

# No fluidsynth
