FROM toolchains/psp AS toolchain

m4_include(`debian-builder-base.m4')m4_dnl

ENV PSPDEV=/usr/local/pspdev HOST=psp
ENV PREFIX=$PSPDEV/$HOST

COPY --from=toolchain $PSPDEV $PSPDEV/

# We add PATH here for *-config and psp specific binaries
ENV \
	ACLOCAL_PATH=$PREFIX/share/aclocal \
	PKG_CONFIG_LIBDIR=$PREFIX/lib \
	PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
	PATH=$PATH:$PSPDEV/bin:$PREFIX/bin \
	CC=$PSPDEV/bin/$HOST-gcc \
	CPP=$PSPDEV/bin/$HOST-cpp \
	CXX=$PSPDEV/bin/$HOST-c++ \
	AR=$PSPDEV/bin/$HOST-ar \
	AS=$PSPDEV/bin/$HOST-as \
	CXXFILT=$PSPDEV/bin/$HOST-c++filt \
	LD=$PSPDEV/bin/$HOST-ld \
	RANLIB=$PSPDEV/bin/$HOST-ranlib \
	STRIP=$PSPDEV/bin/$HOST-strip \
	STRINGS=$PSPDEV/bin/$HOST-strings

m4_include(`run-buildbot.m4')m4_dnl
