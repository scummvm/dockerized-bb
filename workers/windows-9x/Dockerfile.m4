FROM toolchains/windows-9x AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV MINGW32=/opt/toolchains/mingw32 HOST=mingw32

# Add libraries needed by toolchain to run
# Currently libgmp is already installed so don't add it
# That will be simpler when upgrading Debian and not having to adjust versions
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libisl19 \
		libmpc3 \
		libmpfr6 \
		nasm \
		xz-utils && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain ${MINGW32} ${MINGW32}/

ENV PREFIX=${MINGW32}/${HOST}

# We add PATH here for *-config and platform specific binaries
# ucon64 tries to write in home directory, use /tmp for this
ENV \
	def_binaries(`${MINGW32}/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${MINGW32}/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${MINGW32}/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
	PATH=$PATH:${MINGW32}/bin:${MINGW32}/${HOST}/bin

m4_include(`run-buildbot.m4')m4_dnl
