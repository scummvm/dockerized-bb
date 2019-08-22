FROM toolchains/vita AS toolchain

m4_include(`debian-builder-base.m4')m4_dnl

ENV VITASDK=/usr/local/vitasdk HOST=arm-vita-eabi
ENV PREFIX=$VITASDK/$HOST

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libc6-i386 \
		lib32stdc++6 \
		lib32gcc1 && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $VITASDK $VITASDK/

# We add PATH here for *-config and vita specific binaries
ENV \
	ACLOCAL_PATH=$PREFIX/share/aclocal \
	PKG_CONFIG_LIBDIR=$PREFIX/lib \
	PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
	PATH=$PATH:$VITASDK/bin:$PREFIX/bin \
	CC=$VITASDK/bin/$HOST-gcc \
	CPP=$VITASDK/bin/$HOST-cpp \
	CXX=$VITASDK/bin/$HOST-c++ \
	AR=$VITASDK/bin/$HOST-ar \
	AS=$VITASDK/bin/$HOST-as \
	CXXFILT=$VITASDK/bin/$HOST-c++filt \
	GPROF=$VITASDK/bin/$HOST-gprof \
	LD=$VITASDK/bin/$HOST-ld \
	RANLIB=$VITASDK/bin/$HOST-ranlib \
	STRIP=$VITASDK/bin/$HOST-strip \
	STRINGS=$VITASDK/bin/$HOST-strings

m4_include(`run-buildbot.m4')m4_dnl
