m4_define(`DEVKITA64_VERSION',20210306)
# This version of devkitA64 depends on a Debian Stretch
# For now it works with stable-slim, we will have to ensure it stays like that
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
		curl \
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

# As fluidsynth-lite is using cmake, we need to get the platform cmake definitions
# Instead of installing them with pacman (and lose reproductibility) just copy them
# We have patched switch.cmake to make it use CMAKE_EXE_LINKER_FLAGS_INIT instead of CMAKE_EXE_LINKER_FLAGS
COPY devkita64.cmake switch.cmake ${DEVKITPRO}/

ENV PREFIX=${DEVKITPRO}/portlibs/switch HOST=aarch64-none-elf

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITA64}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITA64}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITA64}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/switch/bin

# From pkgbuild-scripts/switchvars.sh
ENV \
	CFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -O2 -ffunction-sections -fdata-sections" \
	CXXFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -O2 -ffunction-sections -fdata-sections" \
	CPPFLAGS="-D__SWITCH__ -I${PREFIX}/include -isystem${DEVKITPRO}/libnx/include" \
	LDFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -L${PREFIX}/lib -L${DEVKITPRO}/libnx/lib" \
	LIBS="-lnx"

# libpng is already installed in original toolchain

# libjpeg-turbo is already installed in original toolchain

helpers_package(faad2)

# libmad is already installed in original toolchain

# libogg is already installed in original toolchain

# libvorbis is already installed in original toolchain

# libtheora is already installed in original toolchain

# flac is already installed in original toolchain

helpers_package(mpeg2dec)

helpers_package(a52dec)

# libtimidity is already installed in original toolchain

# curl is already installed in original toolchain

# freetype is already installed in original toolchain

helpers_package(fribidi)

# sdl2 is already installed in original toolchain

# sdl2_net is already installed in original toolchain

# CMake can't determine endinanness of Switch by running tests
# CMake platform files expect to have compilers in PATH
# CMake don't use CPPFLAGS so add them to CFLAGS
# Copy specific Switch support
COPY packages/fluidsynth-lite lib-helpers/packages/fluidsynth-lite
helpers_package(fluidsynth-lite, -DCMAKE_TOOLCHAIN_FILE=${DEVKITPRO}/switch.cmake -DHAVE_WORDS_BIGENDIAN=true, PATH="${PATH}:${DEVKITA64}/bin")
