m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

RUN dpkg --add-architecture armhf && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++-arm-linux-gnueabihf \
		liba52-dev:armhf \
		libcurl4-openssl-dev:armhf \
		libfaad-dev:armhf \
		libflac-dev:armhf \
		libfluidsynth-dev:armhf \
		libfreetype6-dev:armhf \
		libfribidi-dev:armhf \
		libjpeg62-turbo-dev:armhf \
		libmad0-dev:armhf \
		libmpeg2-4-dev:armhf \
		libpng-dev:armhf \
		libsdl2-dev:armhf \
		libsdl2-net-dev:armhf \
		libtheora-dev:armhf \
		libvorbis-dev:armhf \
		zlib1g-dev:armhf \
		&& \
	rm -rf /var/lib/apt/lists/*

# Raspberry PI librairies are mixed with original Debian
ENV RPI_ROOT=/

ENV HOST=arm-linux-gnueabihf

ENV \
	def_binaries(`/usr/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`/usr/bin/${HOST}-', `gcc, cpp, c++') \
	CC=/usr/bin/${HOST}-gcc \
	def_aclocal(`/usr') \
	PKG_CONFIG_LIBDIR=/usr/lib/$HOST \
	PKG_CONFIG_PATH=/usr/lib/$HOST/pkgconfig

m4_include(`run-buildbot.m4')m4_dnl
