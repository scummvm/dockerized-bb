m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bison \
		dos2unix \
		flex \
		gawk \
		gcc \
		g++ \
		libgmp-dev \
		libisl-dev \
		libmpc-dev \
		libmpfr-dev \
		nasm \
		texinfo \
		xz-utils && \
	rm -rf /var/lib/apt/lists/*

ENV MINGW32=/opt/toolchains/mingw32 HOST=mingw32

local_package(toolchain)

local_package(pe-util, -DCMAKE_INSTALL_PREFIX=${MINGW32})

ENV PREFIX=${MINGW32}/${HOST}

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${MINGW32}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${MINGW32}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${MINGW32}/bin/${HOST}-gcc \
	CPPFLAGS="-D_WIN32_WINNT=0x400" \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${MINGW32}/bin:${MINGW32}/${HOST}/bin


helpers_package(zlib)

helpers_package(libpng1.6)

# Use x86 as PROCESSOR_ARCHITECTURE would return on Windows
helpers_package(libjpeg-turbo, -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=x86)

helpers_package(giflib)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libvorbis)

helpers_package(libtheora)

# FLAC is not compatible with Win9x due to missing functions in MSVCRT.DLL
# _fstat64, _stat64, _wstat64, _wutime64
# helpers_package(flac)

helpers_package(libmikmod)

helpers_package(faad2)

COPY packages/mpeg2dec lib-helpers/packages/mpeg2dec/
helpers_package(mpeg2dec)

COPY packages/a52dec lib-helpers/packages/a52dec/
helpers_package(a52dec)

# Windows 95 doesn't handle well SSE.
# Multithreading uses InterlockedCompareExchange, not present in Windows 95.
helpers_package(libvpx, --as=nasm --disable-sse --disable-multithread)

# TODO: mbedTLS

# TODO: curl

helpers_package(fluidlite, -DCMAKE_SYSTEM_NAME=Windows)

helpers_package(freetype)

helpers_package(fribidi)

helpers_package(libiconv)

local_package(directx)

COPY packages/libsdl1.2 lib-helpers/packages/libsdl1.2/
helpers_package(libsdl1.2)
RUN ln -s ${PREFIX}/bin/sdl-config ${PREFIX}/../bin/${HOST}-sdl-config

# SDL_net is not compatible with Win95 out of the box due to missing DLLs
# WS2_32.DLL and IPHLPAPI.DLL
# helpers_package(sdl-net1.2)

COPY packages/retrowave lib-helpers/packages/retrowave/
helpers_package(retrowave, -DCMAKE_SYSTEM_NAME=Windows)
