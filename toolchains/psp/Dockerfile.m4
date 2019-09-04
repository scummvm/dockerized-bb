FROM toolchains/common AS helpers

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

ENV PSPDEV=/usr/local/pspdev HOST=psp
ENV PREFIX=$PSPDEV/$HOST

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		ca-certificates \
		g++ \
		build-essential \
		autoconf \
		automake \
		cmake \
		doxygen \
		bison \
		flex \
		libncurses5-dev \
		libreadline-dev \
		libusb-dev \
		texinfo \
		zlib1g-dev \
		libtool-bin \
		subversion \
		git \
		tcl \
		unzip \
		wget && \
	echo "dash dash/sh boolean false" | debconf-set-selections && \
	mkdir -p /usr/share/man/man1 && \
	dpkg-reconfigure --frontend=noninteractive dash && \
	rm /usr/share/man/man1/sh.1.gz && \
	rmdir /usr/share/man/man1 && \
	rm -rf /var/lib/apt/lists/*

# Don't need to run prepare as everything we need is already installed (we don't use all build stuff, just fetch)

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

local_package(toolchain)

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
