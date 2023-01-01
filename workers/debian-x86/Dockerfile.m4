m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

m4_define(`APT_ARCH',i386)

RUN dpkg --add-architecture APT_ARCH

m4_include(`debian-libraries.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		g++-i686-linux-gnu \
		nasm \
                && \
        rm -rf /var/lib/apt/lists/*

ENV HOST=i386-linux-gnu BINHOST=i686-linux-gnu

ENV \
	def_binaries(`/usr/bin/${BINHOST}-', `ar, as, c++filt, dwp, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`/usr/bin/${BINHOST}-', `gcc, cpp') \
	CC=/usr/bin/${BINHOST}-gcc \
	CXX=/usr/bin/${BINHOST}-g++ \
	def_aclocal(`/usr') \
	PKG_CONFIG_LIBDIR=/usr/lib/$HOST/pkgconfig:/usr/share/pkgconfig

m4_include(`run-buildbot.m4')m4_dnl
