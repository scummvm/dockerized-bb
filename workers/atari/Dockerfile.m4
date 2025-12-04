FROM toolchains/atari AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV ATARITOOLCHAIN=/opt/toolchains/atari HOST=m68k-atari-mintelf

# Add libraries needed by toolchain to run
# Currently libgmp is already installed so don't add it
# That will be simpler when upgrading Debian and not having to adjust versions
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		dos2unix \
		libmpc3 \
		libmpfr6 \
		libisl23 \
		patch \
		unzip && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain $ATARITOOLCHAIN $ATARITOOLCHAIN

ENV PREFIX=$ATARITOOLCHAIN/$HOST/sys-root/usr

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${HOST}-', `gcc, cpp, c++') \
	CC=${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	PATH=$PATH:${ATARITOOLCHAIN}/bin
# Disable because it doesn't support multilib
#	def_pkg_config(`${PREFIX}')

m4_include(`run-buildbot.m4')m4_dnl
