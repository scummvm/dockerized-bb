FROM toolchains/windows-x86_64 AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV PREFIX=/usr/x86_64-w64-mingw32 HOST=x86_64-w64-mingw32

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		gcc-mingw-w64-x86-64 \
		g++-mingw-w64-x86-64 \
		mingw-w64-tools \
		nasm \
		libz-mingw-w64-dev && \
	rm -rf /var/lib/apt/lists/* && \
	rm $PREFIX/lib/libz.dll.a
# Remove dynamic zlib as we never want to link dynamically with it

COPY --from=toolchain /toolchain/$PREFIX $PREFIX/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`/usr/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`/usr/bin/${HOST}-', `widl, windmc, windres') \
	def_binaries(`/usr/bin/${HOST}-', `gcc, cpp, c++') \
	def_binaries(`/usr/bin/${HOST}-', `pkg-config') \
	CC=/usr/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${PREFIX}/bin

m4_include(`run-buildbot.m4')m4_dnl
