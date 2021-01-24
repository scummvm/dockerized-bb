m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

FROM toolchains/common AS helpers

FROM toolchains/devkitarm

ENV PREFIX=${DEVKITPRO}/portlibs/nds HOST=arm-none-eabi

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DEVKITARM}/bin/${HOST}-', `ar, as, c++filt, ld, link, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DEVKITARM}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DEVKITARM}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DEVKITPRO}/tools/bin:${DEVKITPRO}/portlibs/nds/bin

# From pkgbuild-scripts/ndsvars.sh
ENV \
	CFLAGS="-march=armv5te -mtune=arm946e-s -O2 -ffunction-sections -fdata-sections" \
	CXXFLAGS="-march=armv5te -mtune=arm946e-s -O2 -ffunction-sections -fdata-sections" \
	CPPFLAGS="-D__NDS__ -DARM9 -I${PREFIX}/include -I${DEVKITPRO}/libnds/include" \
	LDFLAGS="-L${PREFIX}/lib -L${DEVKITPRO}/libnds/lib" \
	LIBS="-lnds9"

# libpng is already installed in original toolchain

helpers_package(libjpeg-turbo)

helpers_package(faad2)

helpers_package(libmad)

helpers_package(libogg)

helpers_package(libtheora)

helpers_package(libvorbisidec)

helpers_package(flac)

helpers_package(mpeg2dec)

helpers_package(a52dec)

# curl

# freetype is already installed in original toolchain

helpers_package(fribidi)

# No fluidsynth
