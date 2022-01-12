m4_define(`MXE_VERSION',build-2021-04-22)m4_dnl

m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl
m4_define(`mxe_package', RUN cd "${MXE_DIR}" && \
	$3 make $1 $2 PREFIX="${MXE_PREFIX_DIR}" && \
	make PREFIX="${MXE_PREFIX_DIR}" clean-junk && \
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
		lzip \
		p7zip-full \
		python \
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

# peldd will be used when creating package: only build native version
# Use a local version to have target wrapper scripts
local_mxe_package(pe-util)

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

local_mxe_package(libmpeg2)

mxe_package(a52dec)

local_mxe_package(curl-light)

mxe_package(freetype-bootstrap)

mxe_package(fribidi)

mxe_package(glew)

mxe_package(libiconv)

local_mxe_package(sdl2)

local_mxe_package(sdl2_net)

local_mxe_package(fluidsynth-light)

local_mxe_package(winsparkle)

local_mxe_package(discord-rpc)

local_mxe_package(retrowave)
