m4_include(`debian-builder-base.m4')m4_dnl

RUN dpkg --add-architecture armhf && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++-arm-linux-gnueabihf \
		libcurl4-openssl-dev:armhf \
		libfaad-dev:armhf \
		libflac-dev:armhf \
		libfluidsynth-dev:armhf \
		libfreetype6-dev:armhf \
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
	ACLOCAL_PATH=/usr/share/aclocal \
	PKG_CONFIG_LIBDIR=/usr/lib/$HOST \
	PKG_CONFIG_PATH=/usr/lib/$HOST/pkgconfig \
	CC=/usr/bin/$HOST-gcc \
	CPP=/usr/bin/$HOST-cpp \
	CXX=/usr/bin/$HOST-c++ \
	AR=/usr/bin/$HOST-ar \
	AS=/usr/bin/$HOST-as \
	CXXFILT=/usr/bin/$HOST-c++filt \
	GPROF=/usr/bin/$HOST-gprof \
	LD=/usr/bin/$HOST-ld \
	RANLIB=/usr/bin/$HOST-ranlib \
	STRIP=/usr/bin/$HOST-strip \
	STRINGS=/usr/bin/$HOST-strings

m4_include(`run-buildbot.m4')m4_dnl
