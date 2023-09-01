m4_define(`DEVKITA64_VERSION',20230827)
# This version of devkitA64 depends on a Debian Buster
# For now it works with our version, we will have to ensure it stays like that
FROM devkitpro/devkita64:DEVKITA64_VERSION AS original-toolchain

m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		gnupg \
		libxml2 \
		make \
		pkg-config \
		xz-utils \
		&& \
	rm -rf /var/lib/apt/lists/*

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITA64=${DEVKITPRO}/devkitA64

# Copy A64 toolchain
COPY --from=original-toolchain ${DEVKITPRO}/ ${DEVKITPRO}

ENV PREFIX=${DEVKITPRO}/portlibs/switch HOST=aarch64-none-elf

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITA64}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITA64}/bin/${HOST}-', `gcc, cpp, c++') \
	AR=${DEVKITA64}/bin/${HOST}-gcc-ar \
	RANLIB=${DEVKITA64}/bin/${HOST}-gcc-ranlib \
	CC=${DEVKITA64}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/switch/bin

# From pkgbuild-scripts/switchvars.sh
ENV \
	CFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -O2 -ffunction-sections -fdata-sections" \
	CXXFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -O2 -ffunction-sections -fdata-sections" \
	CPPFLAGS="-D__SWITCH__ -I${PREFIX}/include -isystem ${DEVKITPRO}/libnx/include" \
	LDFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -L${PREFIX}/lib -L${DEVKITPRO}/libnx/lib" \
	LIBS="-lnx"

# zlib is already installed in original toolchain

# libpng is already installed in original toolchain

# libjpeg-turbo is already installed in original toolchain

# giflib is already installed in original toolchain

helpers_package(faad2)

# libmad is already installed in original toolchain

# libogg is already installed in original toolchain

# libvorbis is already installed in original toolchain

# libtheora is already installed in original toolchain

# flac is already installed in original toolchain

# libmikmod is already installed in original toolchain

helpers_package(mpeg2dec)

helpers_package(a52dec)

# libvpx is already installed in original toolchain

# curl is already installed in original toolchain

# freetype is already installed in original toolchain

# fribidi is already installed in original toolchain

# sdl2 is already installed in original toolchain

# sdl2_net is already installed in original toolchain

helpers_package(fluidlite, -DCMAKE_TOOLCHAIN_FILE=${DEVKITPRO}/cmake/Switch.cmake)
