m4_ifdef(`APT_ARCH',`m4_define(`APT_ARCH',`:'APT_ARCH)',`m4_define(`APT_ARCH',)')
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		liba52-dev`'APT_ARCH \
		libboost-program-options-dev`'APT_ARCH \
		libcurl4-openssl-dev`'APT_ARCH \
		libfaad-dev`'APT_ARCH \
		libflac-dev`'APT_ARCH \
		libfluidsynth-dev`'APT_ARCH \
		libfreetype6-dev`'APT_ARCH \
		libfribidi-dev`'APT_ARCH \
		libgif-dev`'APT_ARCH \
		libgtk-3-dev`'APT_ARCH \
		libieee1284-3-dev`'APT_ARCH \
		libjpeg62-turbo-dev`'APT_ARCH \
		libmad0-dev`'APT_ARCH \
		libmikmod-dev`'APT_ARCH \
		libmpeg2-4-dev`'APT_ARCH \
		libogg-dev`'APT_ARCH \
		libpng-dev`'APT_ARCH \
		libreadline-dev`'APT_ARCH \
		libsdl2-dev`'APT_ARCH \
		libsdl2-net-dev`'APT_ARCH \
		libsndio-dev`'APT_ARCH \
		libspeechd-dev`'APT_ARCH \
		libtheora-dev`'APT_ARCH \
		libunity-dev`'APT_ARCH \
		libvorbis-dev`'APT_ARCH \
		libvpx-dev`'APT_ARCH \
		libwxgtk3.0-gtk3-dev`'APT_ARCH \
		zlib1g-dev`'APT_ARCH \
                && \
        rm -rf /var/lib/apt/lists/*
