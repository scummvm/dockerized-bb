m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl
m4_define(`debstrap_package',m4_dnl
`m4_define(`DEBSTRAP_PACKAGES',m4_ifdef(`DEBSTRAP_PACKAGES',m4_dnl
m4_defn(`DEBSTRAP_PACKAGES')` ',)`$1')')

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		fakechroot \
		fakeroot \
		mmdebstrap && \
	rm -rf /var/lib/apt/lists/*

ENV RPI_HOME=/opt/raspberrypi HOST=arm-linux-gnueabihf
ENV RPI_ROOT=$RPI_HOME/sysroot

local_package(compilers)

m4_dnl debstrap_package doesn't actually do anything except appending to DEBSTRAP_PACKAGES variable
debstrap_package(liba52-dev)
debstrap_package(libboost-program-options-dev)
debstrap_package(libcurl4-openssl-dev)
debstrap_package(libfaad-dev)
debstrap_package(libflac-dev)
debstrap_package(libfluidsynth-dev)
debstrap_package(libfreetype6-dev)
debstrap_package(libfribidi-dev)
debstrap_package(libgif-dev)
debstrap_package(libgtk-3-dev)
debstrap_package(libjpeg62-turbo-dev)
debstrap_package(libmad0-dev)
debstrap_package(libmikmod-dev)
debstrap_package(libmpcdec-dev)
debstrap_package(libmpeg2-4-dev)
debstrap_package(libogg-dev)
debstrap_package(libpng-dev)
debstrap_package(libsdl2-dev)
debstrap_package(libsdl2-net-dev)
debstrap_package(libsndio-dev)
debstrap_package(libspeechd-dev)
debstrap_package(libtheora-dev)
debstrap_package(libvorbis-dev)
debstrap_package(libvpx-dev)
debstrap_package(libwxgtk3.0-gtk3-dev)
debstrap_package(zlib1g-dev)

m4_dnl DEBSTRAP_PACKAGES will contain all packages above
local_package(sysroot,DEBSTRAP_PACKAGES)

# Following command is normally executed at postinst step which isn't run by debstrap because it would need a host
# Patch configure script for correct prefix
RUN sed -i -e "s|^\\(prefix=.*\\)/usr|\\1${RPI_ROOT}/usr|" "${RPI_ROOT}/usr/lib/${HOST}/wx/config/gtk3-unicode-3.0" && \
	ln -s "${RPI_ROOT}/usr/lib/${HOST}/wx/config/gtk3-unicode-3.0" "${RPI_ROOT}/usr/bin/wx-config"

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${RPI_HOME}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${RPI_HOME}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${RPI_HOME}/bin/${HOST}-gcc \
	def_aclocal(`${RPI_ROOT}/usr') \
	PKG_CONFIG_LIBDIR=${RPI_ROOT}/usr/lib/$HOST/pkgconfig:${RPI_ROOT}/usr/share/pkgconfig \
	PKG_CONFIG_SYSROOT_DIR=${RPI_ROOT} \
        PATH=$PATH:${RPI_HOME}/bin:${RPI_ROOT}/usr/bin

define_aliases(raspberrypi, dist-generic)
