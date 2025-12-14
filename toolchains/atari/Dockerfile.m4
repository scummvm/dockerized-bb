m4_include(`paths.m4')m4_dnl
m4_define(`local_sdk_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`local_package', COPY packages/$2 lib-helpers/packages/$2/
RUN $4 lib-helpers/multi-build.sh "$1" lib-helpers/packages/$2/build.sh $3)m4_dnl
m4_define(`helpers_package', COPY --from=helpers /lib-helpers/packages/$2 lib-helpers/packages/$2/
RUN $4 lib-helpers/multi-build.sh "$1" lib-helpers/packages/$2/build.sh $3)m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY multi-build.sh functions-platform.sh lib-helpers/

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bison \
		dos2unix \
		flex \
		gcc \
		g++ \
		libgmp-dev \
		libisl-dev \
		libmpc-dev \
		libmpfr-dev \
		patch \
		subversion \
		texinfo \
		zip && \
	rm -rf /var/lib/apt/lists/*

ENV ATARI_TOOLCHAIN=/opt/toolchains/atari

local_sdk_package(toolchain)

COPY m68k-atari-mintelf-pkg-config ${ATARI_TOOLCHAIN}/bin

ENV HOST=m68k-atari-mintelf
ENV PREFIX=$ATARI_TOOLCHAIN/$HOST/sysroot/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${HOST}-', `gcc, cpp, c++') \
	CC=${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	PATH="$PATH:${ATARI_TOOLCHAIN}/bin" \
	CFLAGS="-fno-PIC -O2 -fomit-frame-pointer" \
	CXXFLAGS="-fno-PIC -O2 -fomit-frame-pointer" \
	CPUFLAG_M68020_60="-m68020-60" \
	CPUFLAG_M68030="-m68030" \
	CPUFLAG_M5475="-mcpu=5475"

local_sdk_package(gemlib)
local_sdk_package(ldg)
local_sdk_package(usound)

helpers_package(m68020-60 m5475, zlib)

helpers_package(m5475, libpng1.6)

helpers_package(m5475, libjpeg-turbo, -DWITH_SIMD=OFF)

helpers_package(m5475, giflib)

# No faad2

helpers_package(m5475, libmad, --enable-speed)

helpers_package(m5475, libogg)

helpers_package(m5475, libtheora)

helpers_package(m5475, libvorbis)

# No flac

# No mpeg2dec

# No a52dec

helpers_package(m5475, libmikmod)

# No libmpcdec

# No libvpx

# No openssl

# No curl

helpers_package(m5475, freetype)

# No fribidi

helpers_package(m5475, libsdl1.2, --disable-video-opengl --disable-threads)

# No SDL_Net

# No Fluidsynth

m4_define(`define_atari_aliases', `define_aliases(
$1, $2, $3, \
ASFLAGS=\"\${ASFLAGS} \${CPUFLAG_`'environmentalize($5)}\" \
CFLAGS=\"\${CPUFLAG_`'environmentalize($5)} \${CFLAGS}\" \
CPPFLAGS=\"\${CPPFLAGS} $6\" \
CXXFLAGS=\"\${CPUFLAG_`'environmentalize($5)} \${CXXFLAGS} $6\" \
LDFLAGS=\"\${CPUFLAG_`'environmentalize($5)} \${LDFLAGS}\" \
PKG_CONFIG_LIBDIR=${PREFIX}/lib/$4/pkgconfig \
PATH=${PREFIX}/bin/$4:\${PATH}, $7)')m4_dnl
define_atari_aliases(m68k-atari-mintelf, atarifulldist, --backend=atari, m68020-60, m68020-60, -DUSE_MOVE16 -DUSE_SUPERVIDEL -DUSE_SV_BLITTER -DDISABLE_LAUNCHERDISPLAY_GRID, atari_full)
define_atari_aliases(m68k-atari-mintelf, atarilitedist, --backend=atari --disable-highres --disable-bink, m68020-60, m68030, -DDISABLE_FANCY_THEMES, atari_lite)
define_atari_aliases(m68k-atari-mintelf, fbdist, --backend=sdl, m5475, m5475, , firebee)
