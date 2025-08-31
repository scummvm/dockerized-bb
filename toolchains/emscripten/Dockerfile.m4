m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl
m4_define(`em_package', RUN embuilder build `m4_foreachq(`pkg', `$@',`pkg ')' && embuilder --pic build `m4_foreachq(`pkg', `$@',`pkg ')' && \
	rm -rf /tmp/* ${SYSROOT_DIR}/../ports/*/* ${SYSROOT_DIR}/../build/* && \
	if [ -d "${SYSROOT_DIR}/../ports" ]; then find ${SYSROOT_DIR}/../ports -maxdepth 1 -type f -delete; fi)

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
ENV PREFIX=$EMSDK/scummvm-libs SYSROOT_DIR=${EMSDK}/upstream/emscripten/cache/sysroot

local_package(toolchain)

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${EMSDK}/upstream/emscripten/em', `ar, cc, ranlib, strip') \
	def_binaries(`${EMSDK}/upstream/bin/llvm-', `cxxfilt, nm, objcopy, objdump, strings') \
	AS=${EMSDK}/upstream/bin/wasm-as \
	CXX=${EMSDK}/upstream/emscripten/em++ \
	LD=${EMSDK}/upstream/emscripten/emcc \
	def_aclocal(`${PREFIX}') \
	PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig:${PREFIX}/share/pkgconfig:${SYSROOT_DIR}/lib/pkgconfig:${SYSROOT_DIR}/local/lib/pkgconfig \
	PATH=$PATH:${EMSDK}:${EMSDK}/node/current/bin:${EMSDK}/upstream/emscripten:${SYSROOT_DIR}/bin:${PREFIX}/bin \
	EMSDK_NODE=${EMSDK}/node/current/bin/node \
	CPPFLAGS="-I${PREFIX}/include" \
	CFLAGS="-fPIC" \
	CXXFLAGS="-fPIC" \
	LDFLAGS="-L${PREFIX}/lib"

# Build system libraries for PIC
em_package(libGL, libal, libhtml5, libstubs, libnoexit, libc,
	libdlmalloc, libcompiler_rt, libc++-noexcept, libc++abi-noexcept, libsockets)

em_package(zlib)

em_package(libpng)

em_package(libjpeg)

em_package(giflib)

helpers_package(libmad, --with-pic --enable-fpm=64bit)

em_package(ogg)

em_package(vorbis)

# helpers_package(libtheora, --disable-asm, CFLAGS="$CFLAGS -sUSE_OGG=1 -sUSE_VORBIS=1")
helpers_package(libtheora, --disable-asm, CFLAGS="$CFLAGS -sUSE_OGG=1")

# TODO: flac

helpers_package(faad2)

helpers_package(mpeg2dec)

helpers_package(a52dec)

# TODO: fluidlite

em_package(freetype)

# TODO: fribidi

# This is needed for SDL2
em_package(libGL-getprocaddr)

em_package(sdl2)

em_package(sdl2_net)
