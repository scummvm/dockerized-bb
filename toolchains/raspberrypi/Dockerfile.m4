FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl
m4_define(`multistrap_package',m4_dnl
`m4_define(`MULTISTRAP_PACKAGES',m4_ifdef(`MULTISTRAP_PACKAGES',m4_dnl
m4_defn(`MULTISTRAP_PACKAGES')` ',)`$1')')

FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		multistrap && \
	rm -rf /var/lib/apt/lists/*

ENV RPI_HOME=/opt/raspberrypi HOST=arm-linux-gnueabihf
ENV RPI_ROOT=$RPI_HOME/sysroot

local_package(compilers)

m4_dnl multistrap_package doesn't actually do anything except appending to MULTISTRAP_PACKAGES variable
multistrap_package(liba52-dev)
multistrap_package(libcurl4-openssl-dev)
multistrap_package(libfaad-dev)
multistrap_package(libflac-dev)
multistrap_package(libfluidsynth-dev)
multistrap_package(libfreetype6-dev)
multistrap_package(libfribidi-dev)
multistrap_package(libglew-dev)
multistrap_package(libjpeg62-turbo-dev)
multistrap_package(libmad0-dev)
multistrap_package(libmpeg2-4-dev)
multistrap_package(libpng-dev)
multistrap_package(libsdl2-dev)
multistrap_package(libsdl2-net-dev)
multistrap_package(libtheora-dev)
multistrap_package(libvorbis-dev)
multistrap_package(zlib1g-dev)

# For GLES2
multistrap_package(libraspberrypi-dev)

m4_dnl MULTISTRAP_PACKAGES will contain all packages above
local_package(sysroot,MULTISTRAP_PACKAGES)

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${RPI_HOME}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${RPI_HOME}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${RPI_HOME}/bin/${HOST}-gcc \
	def_aclocal(`${RPI_ROOT}/usr') \
	PKG_CONFIG_LIBDIR=${RPI_ROOT}/usr/lib/$HOST/pkgconfig \
	PKG_CONFIG_SYSROOT_DIR=${RPI_ROOT} \
        PATH=$PATH:${RPI_HOME}/bin:${RPI_ROOT}/usr/bin
