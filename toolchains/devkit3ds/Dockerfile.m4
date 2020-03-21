FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl
m4_define(`pacman_package',`RUN dkp-pacman -Syy --noconfirm `$1' && \
	rm -rf /opt/devkitpro/pacman/var/cache/pacman/pkg/* /opt/devkitpro/pacman/var/lib/pacman/sync/*')m4_dnl

FROM toolchains/devkitarm

# For bannertool
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++ \
		git \
		zip && \
	rm -rf /var/lib/apt/lists/*

COPY functions-platform.sh lib-helpers/

# We need to compile tools before setting environment for all other packages
# We do this now !
local_package(bannertool)

local_package(Project_CTR)

ENV PREFIX=${DEVKITPRO}/portlibs/3ds HOST=arm-none-eabi

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITARM}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITARM}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITARM}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/3ds/bin

# From pkgbuild-scripts/3dsvars.sh
ENV \
	CFLAGS="-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft -O2 -mword-relocations -ffunction-sections -fdata-sections" \
	CXXFLAGS="-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft -O2 -mword-relocations -ffunction-sections -fdata-sections" \
	CPPFLAGS="-D_3DS -I${PREFIX}/include -I${DEVKITPRO}/libctru/include" \
	LDFLAGS="-L${PREFIX}/lib -L${DEVKITPRO}/libctru/lib" \
	LIBS="-lctru"

pacman_package(3ds-libpng)

pacman_package(3ds-libjpeg-turbo)

helpers_package(faad2)

pacman_package(3ds-libmad)

pacman_package(3ds-libogg)

helpers_package(libtheora)

pacman_package(3ds-libvorbisidec)

pacman_package(3ds-flac)

helpers_package(mpeg2dec)

helpers_package(a52dec)

pacman_package(3ds-curl)

pacman_package(3ds-freetype)

# No fluidsynth
