m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

m4_include(`debian-libraries.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		binutils-gold \
		g++ \
		libsdl1.2-dev \
		libsdl-net1.2-dev \
	&& \
	rm -rf /var/lib/apt/lists/*

ENV HOST=x86_64-linux-gnu

ENV \
	def_binaries(`/usr/bin/${HOST}-', `ar, as, c++filt, dwp, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`/usr/bin/${HOST}-', `gcc, cpp') \
	CC=/usr/bin/${HOST}-gcc \
	CXX=/usr/bin/${HOST}-g++ \
	def_aclocal(`/usr') \
	PKG_CONFIG_LIBDIR=/usr/lib/$HOST/pkgconfig:/usr/share/pkgconfig

m4_include(`run-buildbot.m4')m4_dnl
