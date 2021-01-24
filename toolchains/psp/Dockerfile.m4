m4_include(`paths.m4')m4_dnl
m4_include(`packages.m4')m4_dnl

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

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
