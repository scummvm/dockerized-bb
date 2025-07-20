m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl
m4_define(`pspdev_package',m4_dnl
`m4_define(`PSPDEV_PACKAGES',m4_ifdef(`PSPDEV_PACKAGES',m4_dnl
m4_defn(`PSPDEV_PACKAGES')` ',)`$1')')

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bison \
		build-essential \
		ca-certificates \
		cmake \
		fakeroot \
		flex \
		g++ \
		git \
		libtool-bin \
		libarchive-tools \
		libarchive-dev \
		libcurl4-openssl-dev \
		libgmp-dev \
		libgpgme-dev \
		libisl-dev \
		libmpc-dev \
		libmpfr-dev \
		libncurses-dev \
		libreadline-dev \
		libssl-dev \
		libusb-1.0-0-dev \
		zlib1g-dev \
		python3-pip \
		python3-venv \
		texinfo \
		zip \
		unzip \
		wget && \
	rm -rf /var/lib/apt/lists/*

ENV PSPDEV=/usr/local/pspdev HOST=psp
ENV PREFIX=$PSPDEV/$HOST

local_package(toolchain)

# Override config.sub to handle --host=psp properly
local_package(automake)
ENV AUTOMAKE_LIBDIR=$PSPDEV/share/automake

pspdev_package(zlib)

pspdev_package(libpng)

pspdev_package(jpeg)

pspdev_package(libmad)

pspdev_package(libogg)

pspdev_package(libvorbis)

pspdev_package(freetype2)

pspdev_package(sdl2)

local_package(psp-packages,PSPDEV_PACKAGES)

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PSPDEV}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PSPDEV}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PSPDEV}/bin/${HOST}-gcc \
	CFLAGS="-I${PSPDEV}/psp/include -I${PSPDEV}/psp/sdk/include -DPSP -O2 -G0" \
	CXXFLAGS="-I${PSPDEV}/psp/include -I${PSPDEV}/psp/sdk/include -DPSP -O2 -G0" \
	LDFLAGS="-L${PSPDEV}/lib -L${PSPDEV}/psp/lib -L${PSPDEV}/psp/sdk/lib -Wl,-zmax-page-size=128" \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PSPDEV}/bin:${PREFIX}/bin

# Keep additional packages to bare minimum because of memory constraints

helpers_package(giflib,,CFLAGS="${CFLAGS} -fno-PIC")

helpers_package(fribidi)

define_aliases(psp, , --disable-debug --enable-plugins --default-dynamic)
