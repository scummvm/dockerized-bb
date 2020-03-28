FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

m4_include(`packages.m4')m4_dnl

FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Don't need to run prepare as everything we need is already installed (we don't use all build stuff, just fetch)

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

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

ENV PSPDEV=/usr/local/pspdev HOST=psp
ENV PREFIX=$PSPDEV/$HOST

local_package(toolchain)

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${PSPDEV}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${PSPDEV}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${PSPDEV}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${PSPDEV}/bin:${PREFIX}/bin
