FROM toolchains/windows-x86_64 AS toolchain

m4_include(`debian-builder-base.m4')m4_dnl

ENV PREFIX=/usr/x86_64-w64-mingw32 HOST=x86_64-w64-mingw32

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		gcc-mingw-w64-x86-64 \
		g++-mingw-w64-x86-64 \
		mingw-w64-tools \
		nasm \
		libz-mingw-w64-dev && \
	rm -rf /var/lib/apt/lists/* && \
	rm $PREFIX/lib/libz.dll.a
# Remove dynamic zlib as we never want to link dynamically with it

COPY --from=toolchain /toolchain/$PREFIX $PREFIX/

# We add PATH here for *-config binaries
ENV \
	ACLOCAL_PATH=$PREFIX/share/aclocal \
	PKG_CONFIG_LIBDIR=$PREFIX/lib \
	PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
	PATH=$PATH:$PREFIX/bin \
	CC=/usr/bin/$HOST-gcc \
	CPP=/usr/bin/$HOST-cpp \
	CXX=/usr/bin/$HOST-c++ \
	AR=/usr/bin/$HOST-ar \
	AS=/usr/bin/$HOST-as \
	CXXFILT=/usr/bin/$HOST-c++filt \
	GPROF=/usr/bin/$HOST-gprof \
	LD=/usr/bin/$HOST-ld \
	PKG_CONFIG=/usr/bin/$HOST-pkg-config \
	RANLIB=/usr/bin/$HOST-ranlib \
	STRIP=/usr/bin/$HOST-strip \
	STRINGS=/usr/bin/$HOST-strings \
	WIDL=/usr/bin/$HOST-widl \
	WINDMC=/usr/bin/$HOST-windmc \
	WINDRES=/usr/bin/$HOST-windres

m4_include(`run-buildbot.m4')m4_dnl
