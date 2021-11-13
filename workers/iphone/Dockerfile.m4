FROM toolchains/iphone AS toolchain

m4_dnl These settings must be kept in sync between toolchain and worker
m4_define(`PPA_CLANG',-13)m4_dnl
m4_define(`IPHONE_SDK_VERSION',15.0)m4_dnl
m4_define(`IPHONEOS_DEPLOYMENT_TARGET',7.0)m4_dnl

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libxml2 && \
	rm -rf /var/lib/apt/lists/*

# Put this first to share it with all macosx workers
m4_ifdef(`PPA_CLANG',
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
, ``fatal_error(No clang version defined)''))m4_dnl

ENV TARGET_DIR=/opt/iphone

ENV HOST=aarch64-apple-darwin11 \
	`IPHONEOS_DEPLOYMENT_TARGET'=IPHONEOS_DEPLOYMENT_TARGET \
	PREFIX=${TARGET_DIR}/SDK/iPhoneOS`'IPHONE_SDK_VERSION`'.sdk/usr

COPY --from=toolchain $TARGET_DIR $TARGET_DIR/

# Copy libxar to a directory where it will be found (RPATH has been set correctly)
COPY --from=toolchain /usr/lib/libxar.so.* $TARGET_DIR/lib/

# Install compiler-rt
RUN CLANG_LIB_DIR=$(${TARGET_DIR}/bin/${HOST}-clang -print-search-dirs | grep "libraries: =" | \
                        tr '=' ' ' | tr ':' ' ' | awk '{print $2}') ; \
	CLANG_DARWIN_LIB_DIR="${CLANG_LIB_DIR}/lib/darwin" ; \
	mkdir -p "$(dirname "${CLANG_DARWIN_LIB_DIR}")" && \
	ln -s "${TARGET_DIR}/compiler-rt/${CLANG_DARWIN_LIB_DIR}" "${CLANG_DARWIN_LIB_DIR}"

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${TARGET_DIR}/bin/${HOST}-', `ar, as, ld, lipo, nm, ranlib, strings, strip') \
	CPP="${TARGET_DIR}/bin/${HOST}-clang -E" \
	CC=${TARGET_DIR}/bin/${HOST}-clang \
	CXX=${TARGET_DIR}/bin/${HOST}-clang++ \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${TARGET_DIR}/bin:${PREFIX}/bin

m4_include(`run-buildbot.m4')m4_dnl

