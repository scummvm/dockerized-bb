m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bc \
		cpio \
		rsync \
		g++ && \
	rm -rf /var/lib/apt/lists/*

ENV MIYOO_ROOT=/opt/miyoo HOST=arm-miyoo-linux-uclibcgnueabi

local_package(toolchain)

ENV PREFIX=${MIYOO_ROOT}/${HOST}/sysroot/usr

# Use configure CFLAGS
ENV \
	def_binaries(`${MIYOO_ROOT}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${MIYOO_ROOT}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${MIYOO_ROOT}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PKG_CONFIG_SYSROOT_DIR=${MIYOO_ROOT}/${HOST}/sysroot \
	PATH=$PATH:${PREFIX}/bin \
	CFLAGS="-march=armv5te -mtune=arm926ej-s -ffast-math -fomit-frame-pointer -ffunction-sections -fdata-sections" \
	CXXFLAGS="-march=armv5te -mtune=arm926ej-s -ffast-math -fomit-frame-pointer -ffunction-sections -fdata-sections" \
	LDFLAGS="-Wl,--as-needed,--gc-sections"

# zlib is already installed in original toolchain

# libpng is already installed in original toolchain

# libjpeg is already installed in original toolchain

# giflib is already installed in original toolchain

# libmad is already installed in original toolchain

# libogg is already installed in original toolchain

# libvorbis is already installed in original toolchain

# libvorbisidec is already installed in original toolchain

# libtheora is already installed in original toolchain

# flac is already installed in original toolchain

helpers_package(libmikmod)

helpers_package(faad2)

helpers_package(mpeg2dec)

helpers_package(a52dec)

helpers_package(libmpcdec)

helpers_package(libvpx)

# curl is already installed in original toolchain

# freetype is already installed in original toolchain

# fribidi is already installed in original toolchain

# sdl is already installed in original toolchain

# sdl_net is already installed in original toolchain

helpers_package(fluidlite)

define_aliases(miyoo, sd-root, --disable-detection-full --enable-plugins --default-dynamic)
