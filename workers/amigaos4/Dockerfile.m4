FROM toolchains/amigaos4 AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV CROSS_PREFIX=/usr/local/amigaos4 HOST=ppc-amigaos
ENV PREFIX=$CROSS_PREFIX/$HOST

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		lhasa \
		libgmp10 \
		libmpc3 \
		libmpfr6 && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $CROSS_PREFIX $CROSS_PREFIX/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${CROSS_PREFIX}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${CROSS_PREFIX}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${CROSS_PREFIX}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${CROSS_PREFIX}/bin:${PREFIX}/bin \
	LDFLAGS="-athread=native"

m4_include(`run-buildbot.m4')m4_dnl
