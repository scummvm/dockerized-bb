m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl
m4_define(`helpers_package', helpers_package($1,$2,$3) && osxcross-macports fake-install $1 && rm -Rf ${TARGET_DIR}/macports/cache)m4_dnl
m4_define(`common_package', COPY --from=apple-common /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`ports_package', RUN $3 osxcross-macports ``${MACOSX_PORTS_ARCH_ARG}'' -s install $1 $2 && rm -Rf ${TARGET_DIR}/macports/cache)m4_dnl

FROM toolchains/apple-sdks AS sdks
FROM toolchains/apple-common AS apple-common

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++ \
		libbz2-dev \
		liblzma-dev \
		libxml2-dev \
		libssl-dev \
		python3-setuptools \
		uuid-dev \
		zlib1g-dev \
		&& \
	rm -rf /var/lib/apt/lists/*

# Optimize iphone and macosx builds by defining TARGET_DIR at the moment we need it
m4_ifdef(`OSXCROSS_CLANG',
ENV TARGET_DIR=/opt/osxcross

# Compile clang before anything else to reuse the result in all MacOSX toolchains
common_package(osxcross-clang)
, m4_ifdef(`PPA_CLANG',
RUN . /etc/os-release && \
	echo "deb http://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME`'PPA_CLANG`' main" > /etc/apt/sources.list.d/clang.list && \
	wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
	rm -f "${HOME}/.wget-hsts" && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang`'PPA_CLANG`' \
		llvm`'PPA_CLANG`'-dev \
		libomp`'PPA_CLANG`'-dev \
		&& \
	rm -rf /var/lib/apt/lists/* && \
	rm /etc/apt/sources.list.d/clang.list /etc/apt/trusted.gpg

# Add newly installed LLVM to path
ENV PATH=$PATH:/usr/lib/llvm`'PPA_CLANG`'/bin

ENV TARGET_DIR=/opt/osxcross
, m4_ifdef(`DEBIAN_CLANG',
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang`'DEBIAN_CLANG \
		llvm`'DEBIAN_CLANG`'-dev \
		&& \
	for f in /usr/lib/llvm`'DEBIAN_CLANG/bin/*; do ln -sf $f /usr/bin/$(basename $f); done && \
	rm -rf /var/lib/apt/lists/*

ENV TARGET_DIR=/opt/osxcross
, ```fatal_error(No clang version defined)''')))m4_dnl

ENV SDK_DIR=/opt/sdk

# Keep in sync with apple_sdks
COPY --from=sdks /sdk/MacOSX`'MACOSX_SDK_VERSION`'* ${SDK_DIR}/

m4_dnl define this to add toolchain specific patch (new OSX version for example)
m4_ifdef(`PATCH_OSXCROSS',
COPY packages/osxcross lib-helpers/packages/osxcross,)
common_package(osxcross)

# Install rcodesign for ad-hoc signing
common_package(rcodesign)

# Use same prefix as in MacPorts and DESTDIR to install at correct place
# That way, we can use osxcross pkg-config wrapper even for our packages
ENV HOST=MACOSX_TARGET_ARCH-apple-darwin`'MACOSX_TARGET_VERSION \
	`MACOSX_DEPLOYMENT_TARGET'=MACOSX_DEPLOYMENT_TARGET \
	`MACOSX_PORTS_ARCH_ARG'=MACOSX_PORTS_ARCH_ARG \
	OSXCROSS_MACPORTS_MIRROR="http://packages.macports.org" \
	DESTDIR=${TARGET_DIR}/macports/pkgs \
	PREFIX=/opt/local

# We add PATH here for *-config and platform specific binaries
# We define PKG_CONFIG_SYSROOT_DIR to let pkg-config behave the same way when invoked without using wrapper
# We define OSXCROSS_MP_INC to have clang automatically add macports path
ENV \
	def_binaries(`${TARGET_DIR}/bin/${HOST}-', `ar, as, ld, lipo, nm, ranlib, strings, strip') \
	CPP="${TARGET_DIR}/bin/${HOST}-cc -E" \
	CC=${TARGET_DIR}/bin/${HOST}-cc \
	CXX=${TARGET_DIR}/bin/${HOST}-c++ \
	CFLAGS="m4_foreachq(`_arch', `MACOSX_ARCHITECTURES',`-arch _arch ')" \
	CXXFLAGS="m4_foreachq(`_arch', `MACOSX_ARCHITECTURES',`-arch _arch ')" \
	LDFLAGS="m4_foreachq(`_arch', `MACOSX_ARCHITECTURES',`-arch _arch ')" \
	def_aclocal(`${TARGET_DIR}/macports/pkgs/${PREFIX}') \
	PKG_CONFIG_SYSROOT_DIR=${DESTDIR} \
	def_pkg_config(`${DESTDIR}/${PREFIX}') \
	PATH=$PATH:${TARGET_DIR}/bin:${TARGET_DIR}/SDK/MacOSX`'MACOSX_SDK_VERSION`'.sdk/usr/bin:${DESTDIR}/${PREFIX}/bin \
	OSXCROSS_MP_INC=1

# Generate meson cross file for GLib
crossgen(darwin, MACOSX_TARGET_ARCH)

# zlib is provided in SDK but libpng uses ports one
ports_package(zlib)

ports_package(bzip2)

ports_package(libpng)

ports_package(libjpeg-turbo)

# giflib5 in ports is installed in subdirectory not standard
helpers_package(giflib)

# Ports package is not static anymore (since faad 2.11) due to build system change in upstream
helpers_package(faad2)

# Ports package is not static anymore (since mad 0.16.4) due to build system change in upstream
helpers_package(libmad)

ports_package(libtheora)

ports_package(libvorbis)

ports_package(libmikmod)

helpers_package(flac)

# mpeg2dec in ports comes with dependencies on X11 and SDL
# Even if Portfile can avoid it, that's not precompiled and osxcross only handles binary download
helpers_package(mpeg2dec)

ports_package(a52dec)

ports_package(libmpcdec)

ports_package(libvpx)

# No curl as it's provided in SDK

# Ports package is linked with brotli and fails to link statically because of
# different file names. Instead of patching, just build ourselves without brotli
helpers_package(freetype)

ports_package(fribidi)

# This is a shim package which uses ports but fixes paths in sdl2-config
common_package(libsdl2)

ports_package(libsdl2_net)

# Lighten glib build by removing Objective C and Cocoa and fix intl detection
COPY --from=apple-common /lib-helpers/packages/fluidsynth lib-helpers/packages/fluidsynth
helpers_package(fluidsynth, -DCMAKE_SYSTEM_NAME=Darwin -DLIB_SUFFIX= -DCMAKE_FRAMEWORK_PATH=${TARGET_DIR}/SDK/MacOSX`'MACOSX_SDK_VERSION`'.sdk/usr/lib)

helpers_package(retrowave, -DCMAKE_SYSTEM_NAME=Darwin)

# Toolchain specific packages will go in the dedicated file now
