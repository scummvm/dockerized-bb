FROM toolchains/dreamcast AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV DCTOOLCHAIN=/opt/toolchains/dc HOST=sh-elf

# Add libraries needed by toolchain to run
# Currently libgmp is already installed so don't add it
# That will be simpler when upgrading Debian and not having to adjust versions
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libmpc3 \
		libmpfr6 \
		libisl23 && \
	rm -rf /var/lib/apt/lists/*

# Don't copy arm-eabi as we don't need it
COPY --from=toolchain $DCTOOLCHAIN/sh-elf $DCTOOLCHAIN/sh-elf/
COPY --from=toolchain $DCTOOLCHAIN/ronin $DCTOOLCHAIN/ronin/
COPY --from=toolchain $DCTOOLCHAIN/bin $DCTOOLCHAIN/bin/
COPY --from=toolchain $DCTOOLCHAIN/share $DCTOOLCHAIN/share/

ENV PREFIX=$DCTOOLCHAIN/sh-elf/${HOST}

# We add PATH here for *-config and platform specific binaries
ENV \
	def_binaries(`${DCTOOLCHAIN}/sh-elf/bin/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${DCTOOLCHAIN}/sh-elf/bin/${HOST}-', `gcc, cpp, c++') \
	CC=${DCTOOLCHAIN}/sh-elf/bin/${HOST}-gcc \
	def_aclocal(`${PREFIX}') \
	def_pkg_config(`${PREFIX}') \
        PATH=$PATH:${DCTOOLCHAIN}/bin:${DCTOOLCHAIN}/sh-elf/bin \
	RONINDIR=${DCTOOLCHAIN}/ronin \
	IP_TEMPLATE_FILE=${DCTOOLCHAIN}/share/makeip/IP.TMPL

m4_include(`run-buildbot.m4')m4_dnl
