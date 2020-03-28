FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl
m4_define(`pacman_package',`RUN dkp-pacman -Syy --noconfirm `$1' && \
	rm -rf /opt/devkitpro/pacman/var/cache/pacman/pkg/* /opt/devkitpro/pacman/var/lib/pacman/sync/*')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		gnupg \
		libxml2 \
		make \
		pkg-config \
		wget \
		xz-utils \
		&& \
	rm -rf /var/lib/apt/lists/*

ARG DKP_PACMAN=1.0.1

RUN wget https://github.com/devkitPro/pacman/releases/download/devkitpro-pacman-${DKP_PACMAN}/devkitpro-pacman.deb && \
	dpkg -i devkitpro-pacman.deb && \
	rm -f $HOME/.wget-hsts devkitpro-pacman.deb && \
	rm -rf /opt/devkitpro/pacman/var/cache/pacman/pkg/* /opt/devkitpro/pacman/var/lib/pacman/sync/*

pacman_package(gamecube-dev wii-dev wiiu-dev)

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITPPC=${DEVKITPRO}/devkitPPC

local_package(libgxflux)

# Define everything only now as libgxflux already handles all of this

ENV PREFIX=${DEVKITPRO}/portlibs/ppc HOST=powerpc-eabi

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITPPC}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITPPC}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITPPC}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/ppc/bin

# From pkgbuild-scripts/ppcvars.sh
ENV \
	CFLAGS="-O2 -mcpu=750 -meabi -mhard-float -ffunction-sections -fdata-sections" \
	CXXFLAGS="-O2 -mcpu=750 -meabi -mhard-float -ffunction-sections -fdata-sections" \
	CPPFLAGS="-DGEKKO -I${PREFIX}/include" \
	LDFLAGS="-L${PREFIX}/lib"

pacman_package(ppc-libpng)

pacman_package(ppc-libjpeg-turbo)

helpers_package(faad2)

pacman_package(ppc-libmad)

pacman_package(ppc-libogg)

helpers_package(libtheora)

pacman_package(ppc-libvorbisidec)

# Disable AltiVec as it's not supported by targets and SSE2 because configure script enables it
# Copy specific patch to disable FORTIFY as toolchain doesn't seem to support it
COPY packages/flac lib-helpers/packages/flac
helpers_package(flac, --disable-altivec)

helpers_package(mpeg2dec, , CFLAGS="$CFLAGS -mno-altivec")

helpers_package(a52dec)

# curl

pacman_package(ppc-freetype)

# No fluidsynth
