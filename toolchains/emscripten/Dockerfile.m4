m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY functions-platform.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		binutils \
		build-essential \
		ca-certificates \
		file \
		git \
		python3 \
		python3-pip && \
	rm -rf /var/lib/apt/lists/*

ENV EMSDK=/usr/local/emscripten HOST=wasm32-unknown-none
ENV PREFIX=$EMSDK/scummvm-libs

local_package(toolchain)

# We add PATH here for *-config and platform specific binaries
ENV \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${EMSDK}:${EMSDK}/node/14.18.2_64bit/bin:${EMSDK}/upstream/emscripten:${PREFIX}/bin \
	CPPFLAGS="-I${PREFIX}/include" \
	LDFLAGS="-L${PREFIX}/lib"

RUN emcc -s USE_ZLIB -E - < /dev/null

RUN emcc -s USE_LIBPNG=1 -E - < /dev/null

RUN emcc -s USE_LIBJPEG=1 -E - < /dev/null

RUN emcc -s USE_GIFLIB=1 -E - < /dev/null

helpers_package(libmad, --with-pic --enable-fpm=no)

RUN emcc -s USE_OGG=1 -E - < /dev/null

RUN emcc -s USE_VORBIS=1 -E - < /dev/null

# helpers_package(libtheora, --disable-asm, CFLAGS="-fPIC -s USE_OGG=1 -s USE_VORBIS=1")
helpers_package(libtheora, --disable-asm, CFLAGS="-fPIC -s USE_OGG=1")

# TODO: flac

helpers_package(faad2, , CFLAGS="-fPIC")

helpers_package(mpeg2dec, , CFLAGS="-fPIC")

helpers_package(a52dec, , CFLAGS="-fPIC")


# TODO: fluidlite

RUN emcc -s USE_FREETYPE=1 -E - < /dev/null

# TODO: fribidi

RUN emcc -s USE_SDL=2 -E - < /dev/null

RUN emcc -s USE_SDL_NET=2 -E - < /dev/null
