m4_define(`MXE_VERSION',9f349e0de62a4a68bfc0f13d835a6c685dae9daa)m4_dnl

m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl
m4_define(`mxe_package', RUN cd "${MXE_DIR}" && \
	$3 make $1 $2 -j$(nproc) PREFIX="${MXE_PREFIX_DIR}" && \
	make PREFIX="${MXE_PREFIX_DIR}" -j$(nproc) clean-junk && \
	rm -f $HOME/.wget-hsts && find /tmp -mindepth 1 -delete)m4_dnl
m4_dnl FIXME: don't hardcode /usr/src here
m4_define(`local_mxe_package', COPY packages/$1 lib-helpers/packages/$1/
mxe_package($1, MXE_PLUGIN_DIRS="/usr/src/lib-helpers/packages/$1/" $2, $3))

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bison \
		dos2unix \
		flex \
		g++ \
		gperf \
		intltool \
		libgdk-pixbuf2.0-bin \
		libssl-dev \
		libtool-bin \
		libzstd-dev \
		lld \
		lzip \
		nasm \
		p7zip-full \
		python-is-python3 \
		python3-mako \
		python3-packaging \
		ruby && \
	rm -rf /var/lib/apt/lists/*

# MXE_DIR is where tree will be located and MXE_PREFIX_DIR is where stuff gets installed
# As MXE changes are mainly packages related, set version here instead of in toolchain script
ENV MXE_DIR=/opt/mxe-src \
	MXE_PREFIX_DIR=/opt/mxe \
	`MXE_VERSION'=MXE_VERSION

# Add MXE bin directory to PATH
ENV PATH=$PATH:${MXE_PREFIX_DIR}/bin

local_package(toolchain)

# Install CMake now as it's used for several packages later as it's cleaner
# That will install cmake configuration files as well
mxe_package(cmake)

# peldd will be used when creating package
# Use local patch to avoid referencing Qt5 non-existent path and for ce build of wrapper
local_mxe_package(pe-util)

# LLD links ScummVM faster
mxe_package(lld)

# Install everything through MXE to not mess with environment variables
# This lets MXE build all platforms and avoids to mess with its settings

mxe_package(zlib)

mxe_package(libpng)

# Patch libjpeg-turbo to not install it in its own subdirectory
local_mxe_package(libjpeg-turbo)

mxe_package(giflib)

mxe_package(faad2)

mxe_package(libmad)

mxe_package(ogg)

mxe_package(vorbis)

mxe_package(theora)

mxe_package(flac)

mxe_package(libmikmod)

local_mxe_package(libmpeg2)

mxe_package(a52dec)

# Patch libmpcdec to install the static library without a _static suffix
local_mxe_package(libmpcdec)

mxe_package(libvpx)

local_mxe_package(curl-light)

mxe_package(freetype-bootstrap)

mxe_package(fribidi)

mxe_package(libiconv)

local_mxe_package(sdl2)

mxe_package(sdl2_net)

local_mxe_package(fluidlite)

local_mxe_package(winsparkle)

local_mxe_package(discord-rpc)

local_mxe_package(retrowave)

m4_define(`define_mxe_aliases', `define_aliases(
$1-w64-mingw32.static, win32dist-mingw DESTDIR=win32dist-mingw, , \
CXX=${MXE_PREFIX_DIR}/bin/$1-w64-mingw32.static-c++ \
STRIP=${MXE_PREFIX_DIR}/bin/$1-w64-mingw32.static-strip \
STRINGS=${MXE_PREFIX_DIR}/bin/$1-w64-mingw32.static-strings \
PKG_CONFIG_LIBDIR=${MXE_PREFIX_DIR}/$1-w64-mingw32.static/lib/pkgconfig \
PATH=$PATH:${MXE_PREFIX_DIR}/$1-w64-mingw32.static/bin, $2)')m4_dnl
define_mxe_aliases(i686, x86)
define_mxe_aliases(x86_64, x86_64)
