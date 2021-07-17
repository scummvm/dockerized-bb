m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bison \
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

local_package(toolchain)

ENV HOST=mingw32
ENV PREFIX=/opt/toolchains/mingw32/${HOST}

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`/opt/toolchains/mingw32/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`/opt/toolchains/mingw32/bin/${HOST}-', `gcc, cpp, c++') \
	CC=/opt/toolchains/mingw32/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:/opt/toolchains/mingw32/bin


helpers_package(zlib)

helpers_package(libpng1.6)

helpers_package(libjpeg-turbo)

helpers_package(giflib)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libvorbis)

helpers_package(libtheora)

# FLAC is not compatible with Win9x due to missing functions in MSVCRT.DLL
# _fstat64, _stat64, _wstat64, _wutime64
# helpers_package(flac)

helpers_package(faad2)

helpers_package(mpeg2dec)

helpers_package(a52dec)

# TODO: mbedTLS

# TODO: curl

# TODO: FluidLite

helpers_package(freetype)

helpers_package(fribidi)

local_package(directx)

helpers_package(libsdl1.2, --enable-shared)

helpers_package(sdl-net1.2)

# TODO: glew

# TODO: libiconv

