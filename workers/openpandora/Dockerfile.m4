FROM toolchains/openpandora AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV TOOLCHAIN=/opt/openpandora HOST=arm-angstrom-linux-gnueabi

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libxml2-utils \
		squashfs-tools && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $TOOLCHAIN $TOOLCHAIN/

ENV PREFIX=${TOOLCHAIN}/${HOST}/sysroot/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${TOOLCHAIN}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${TOOLCHAIN}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${TOOLCHAIN}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin

# To please OpenPandora port makefile
RUN mkdir -p ${TOOLCHAIN}/${HOST}/usr/lib && ln -s ${PREFIX}/lib/libFLAC.so.8.2.0 ${TOOLCHAIN}/${HOST}/usr/lib

m4_include(`run-buildbot.m4')m4_dnl
