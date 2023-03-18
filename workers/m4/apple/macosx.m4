FROM toolchains/TOOLCHAIN AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libxml2 && \
	rm -rf /var/lib/apt/lists/*

# Put this first to share it with all macosx workers
m4_ifdef(`OSXCROSS_CLANG',
m4_dnl Nothing to do, install will be done just after
, m4_ifdef(`PPA_CLANG',
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		gnupg \
		wget && \
	rm -rf /var/lib/apt/lists/*

RUN . /etc/os-release && \
	echo "deb http://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME`'PPA_CLANG`' main" > /etc/apt/sources.list.d/clang.list && \
	wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang`'PPA_CLANG`' \
		llvm`'PPA_CLANG`' \
		&& \
	rm -rf /var/lib/apt/lists/* && \
	rm /etc/apt/sources.list.d/clang.list /etc/apt/trusted.gpg

# Add newly installed LLVM to path
ENV PATH=$PATH:/usr/lib/llvm`'PPA_CLANG`'/bin
, m4_ifdef(`DEBIAN_CLANG',
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang`'DEBIAN_CLANG \
		llvm`'DEBIAN_CLANG`' \
		&& \
	for f in /usr/lib/llvm`'DEBIAN_CLANG/bin/*; do ln -sf $f /usr/bin/$(basename $f); done && \
	rm -rf /var/lib/apt/lists/*
, ```fatal_error(No clang version defined)''')))m4_dnl

ENV TARGET_DIR=/opt/osxcross

# Use same prefix as in MacPorts and DESTDIR to install at correct place
# That way, we can use osxcross pkg-config wrapper even for our packages
ENV HOST=MACOSX_TARGET_ARCH-apple-darwin`'MACOSX_TARGET_VERSION \
	`MACOSX_DEPLOYMENT_TARGET'=MACOSX_DEPLOYMENT_TARGET \
	`MACOSX_PORTS_ARCH_ARG'=MACOSX_PORTS_ARCH_ARG \
	DESTDIR=${TARGET_DIR}/macports/pkgs \
	PREFIX=/opt/local

COPY --from=toolchain $TARGET_DIR $TARGET_DIR/

RUN CLANG_LIB_DIR=$(clang -print-search-dirs | grep "libraries: =" | \
	tr '=' ' ' | tr ':' ' ' | awk '{print $2}') && \
	CLANG_INCLUDE_DIR="${CLANG_LIB_DIR}/include" && \
	CLANG_DARWIN_LIB_DIR="${CLANG_LIB_DIR}/lib/darwin" && \
	mkdir -p "$(dirname "${CLANG_DARWIN_LIB_DIR}")" && \
	ln -s ${TARGET_DIR}/compiler_rt/lib/darwin ${CLANG_DARWIN_LIB_DIR}

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

m4_include(`run-buildbot.m4')m4_dnl
