FROM toolchains/ps3 AS toolchain

m4_include(`debian-builder-base.m4')m4_dnl

ENV PS3DEV=/usr/local/ps3dev HOST=powerpc64-ps3-elf
ENV PSL1GHT=$PS3DEV PREFIX=$PS3DEV/ppu

# Add libraries needed by toolchain to run
# Currently libgmp libssl zlib and python are already installed so don't add them
# That will be simpler when upgrading Debian and not having to adjust versions
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libelf1 && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $PS3DEV $PS3DEV/

# We add PATH here for *-config and psp specific binaries
ENV \
	ACLOCAL_PATH=$PS3DEV/portlibs/ppu/share/aclocal \
	PKG_CONFIG_LIBDIR=$PS3DEV/portlibs/ppu/lib \
	PKG_CONFIG_PATH=$PS3DEV/portlibs/ppu/lib/pkgconfig \
	PATH=$PATH:$PS3DEV/bin:$PS3DEV/ppu/bin:$PS3DEV/spu/bin:$PS3DEV/portlibs/ppu/bin \
	CC=$PREFIX/bin/$HOST-gcc \
	CPP=$PREFIX/bin/$HOST-cpp \
	CXX=$PREFIX/bin/$HOST-c++ \
	AR=$PREFIX/bin/$HOST-ar \
	AS=$PREFIX/bin/$HOST-as \
	CXXFILT=$PREFIX/bin/$HOST-c++filt \
	LD=$PREFIX/bin/$HOST-ld \
	RANLIB=$PREFIX/bin/$HOST-ranlib \
	STRIP=$PREFIX/bin/$HOST-strip \
	STRINGS=$PREFIX/bin/$HOST-strings

m4_include(`run-buildbot.m4')m4_dnl
