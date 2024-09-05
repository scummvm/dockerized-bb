m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl
m4_define(`vdpm_package', RUN lib-helpers/install-vdpm.sh $1)m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY functions-platform.sh install-vdpm.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libc6-i386 \
		lib32stdc++6 \
		lib32gcc-s1 \
		zip && \
	rm -rf /var/lib/apt/lists/*

ENV VITASDK=/usr/local/vitasdk HOST=arm-vita-eabi
ENV PREFIX=$VITASDK/$HOST

local_package(toolchain)

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${VITASDK}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${VITASDK}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${VITASDK}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${VITASDK}/bin:${PREFIX}/bin

vdpm_package(zlib)

vdpm_package(libpng)

vdpm_package(libjpeg-turbo)

helpers_package(giflib)

vdpm_package(libmad)

vdpm_package(libogg)

vdpm_package(libvorbis)

vdpm_package(libtheora)

vdpm_package(flac)

vdpm_package(libmikmod)

helpers_package(faad2)

vdpm_package(libmpeg2)

helpers_package(a52dec)

helpers_package(libmpcdec)

vdpm_package(libvpx)

vdpm_package(openssl)

vdpm_package(curl)

vdpm_package(freetype)

vdpm_package(fribidi)

vdpm_package(FluidLite)

vdpm_package(sdl2)

vdpm_package(sdl2_net)
