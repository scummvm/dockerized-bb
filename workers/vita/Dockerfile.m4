FROM toolchains/vita AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV VITASDK=/usr/local/vitasdk HOST=arm-vita-eabi
ENV PREFIX=$VITASDK/$HOST

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libc6-i386 \
		lib32stdc++6 \
		lib32gcc-s1 && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $VITASDK $VITASDK/

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${VITASDK}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${VITASDK}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${VITASDK}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${VITASDK}/bin:${PREFIX}/bin

m4_include(`run-buildbot.m4')m4_dnl
