FROM toolchains/riscos AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV GCCSDK_INSTALL_CROSSBIN=/usr/local/gccsdk/cross/bin \
	GCCSDK_INSTALL_ENV=/usr/local/gccsdk/env

COPY --from=toolchain /usr/local/gccsdk /usr/local/gccsdk/

ENV PREFIX=${GCCSDK_INSTALL_ENV} HOST=arm-unknown-riscos

# Put GCCSDK_INSTALL_CROSSBIN before PATH because it overrides some binaries like zip
# Don't specify -O2 for worker, it breaks endian detection and configure already sets it
ENV \
	def_binaries(`${GCCSDK_INSTALL_CROSSBIN}/${HOST}-', `ar, as, c++filt, ld, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`${GCCSDK_INSTALL_CROSSBIN}/${HOST}-', `gcc, cpp, c++') \
	CC="${GCCSDK_INSTALL_CROSSBIN}/${HOST}-gcc" \
	PATH="${GCCSDK_INSTALL_CROSSBIN}:${PATH}" \
	CFLAGS="-ffunction-sections -fdata-sections -mno-poke-function-name" \
	CXXFLAGS="-ffunction-sections -fdata-sections -mno-poke-function-name" \
	LDFLAGS="-Wl,--gc-sections" \
	CFLAGS_STD="" \
	CXXFLAGS_STD="" \
	ASFLAGS_VFP="-mfpu=vfp" \
	CFLAGS_VFP="-mfpu=vfp" \
	CXXFLAGS_VFP="-mfpu=vfp" \
	LDFLAGS_VFP="-mfpu=vfp"

m4_include(`run-buildbot.m4')m4_dnl
