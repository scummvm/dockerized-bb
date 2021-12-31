FROM toolchains/gcw0 AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		squashfs-tools && \
	rm -rf /var/lib/apt/lists/*

ENV GCW_TOOLCHAIN=/opt/gcw0-toolchain HOST=mipsel-gcw0-linux-uclibc

COPY --from=toolchain ${GCW_TOOLCHAIN} ${GCW_TOOLCHAIN}/

ENV PREFIX=${GCW_TOOLCHAIN}/${HOST}/sysroot/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${GCW_TOOLCHAIN}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${GCW_TOOLCHAIN}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${GCW_TOOLCHAIN}/bin/$HOST-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${PREFIX}/bin \
	CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
	CFLAGS="-O2 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
	CXXFLAGS="-O2 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64"

m4_include(`run-buildbot.m4')m4_dnl
