FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl
m4_define(`pacman_package',`RUN dkp-pacman -Syy --noconfirm `$1' && \
	rm -rf /opt/devkitpro/pacman/var/cache/pacman/pkg/* /opt/devkitpro/pacman/var/lib/pacman/sync/*')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

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

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

ARG DKP_PACMAN=1.0.1

RUN wget https://github.com/devkitPro/pacman/releases/download/devkitpro-pacman-${DKP_PACMAN}/devkitpro-pacman.deb && \
	dpkg -i devkitpro-pacman.deb && \
	rm -f $HOME/.wget-hsts devkitpro-pacman.deb && \
	rm -rf /opt/devkitpro/pacman/var/cache/pacman/pkg/* /opt/devkitpro/pacman/var/lib/pacman/sync/*

pacman_package(switch-dev)

# As fluidsynth-lite is using cmake, we need to get the platform cmake definitions
pacman_package(devkitpro-pkgbuild-helpers)

ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITA64=${DEVKITPRO}/devkitA64

ENV PREFIX=${DEVKITPRO}/portlibs/switch HOST=aarch64-none-elf

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITA64}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITA64}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITA64}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/switch/bin

# From pkgbuild-scripts/switchvars.sh
ENV \
	CFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -O2 -ffunction-sections -fdata-sections" \
	CXXFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -O2 -ffunction-sections -fdata-sections" \
	CPPFLAGS="-D__SWITCH__ -I${PREFIX}/include -isystem${DEVKITPRO}/libnx/include" \
	LDFLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -L${PREFIX}/lib -L${DEVKITPRO}/libnx/lib" \
	LIBS="-lnx"

pacman_package(switch-libpng)

pacman_package(switch-libjpeg-turbo)

helpers_package(faad2)

pacman_package(switch-libmad)

pacman_package(switch-libogg)

pacman_package(switch-libvorbis)

pacman_package(switch-libtheora)

pacman_package(switch-flac)

helpers_package(mpeg2dec)

helpers_package(a52dec)

pacman_package(switch-libtimidity)

pacman_package(switch-curl)

pacman_package(switch-freetype)

pacman_package(switch-sdl2)

pacman_package(switch-sdl2_net)

# CMake can't determine endinanness of Switch by running tests
# CMake platform files expect to have compilers in PATH
# CMake don't use CPPFLAGS so add them to CFLAGS
helpers_package(fluidsynth-lite, -DCMAKE_TOOLCHAIN_FILE=${DEVKITPRO}/switch.cmake -DHAVE_WORDS_BIGENDIAN=true, CFLAGS="${CPPFLAGS} ${CFLAGS}" PATH="${PATH}:${DEVKITA64}/bin")
