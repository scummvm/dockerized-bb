m4_include(`debian-builder-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++ \
		liba52-dev \
		libcurl4-openssl-dev \
		libfaad-dev \
		libflac-dev \
		libfluidsynth-dev \
		libfreetype6-dev \
		libfribidi-dev \
		libjpeg62-turbo-dev \
		libmad0-dev \
		libmpeg2-4-dev \
		libpng-dev \
		libsdl2-dev \
		libsdl2-net-dev \
		libtheora-dev \
		libvorbis-dev \
		zlib1g-dev \
                && \
        rm -rf /var/lib/apt/lists/*

m4_include(`run-buildbot.m4')m4_dnl
