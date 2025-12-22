FROM toolchains/emscripten AS toolchain

m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

ENV EMSDK=/usr/local/emscripten HOST=wasm32-unknown-none
ENV PREFIX=$EMSDK/scummvm-libs SYSROOT_DIR=${EMSDK}/upstream/emscripten/cache/sysroot

# Add libraries needed by toolchain to run
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libatomic1 && \
	rm -rf /var/lib/apt/lists/*

COPY --from=toolchain ${EMSDK} ${EMSDK}/

# We add PATH here for *-config and platform specific binaries
# Prevent the build process to build ports
ENV \
	EM_FROZEN_CACHE=1 \
	def_binaries(`${EMSDK}/upstream/emscripten/em', `ar, cc, ranlib, strip') \
	def_binaries(`${EMSDK}/upstream/bin/llvm-', `cxxfilt, nm, objcopy, objdump, strings') \
	AS=${EMSDK}/upstream/bin/wasm-as \
	CXX=${EMSDK}/upstream/emscripten/em++ \
	LD=${EMSDK}/upstream/emscripten/emcc \
	def_aclocal(`${PREFIX}') \
	PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig:${PREFIX}/share/pkgconfig:${SYSROOT_DIR}/lib/pkgconfig:${SYSROOT_DIR}/local/lib/pkgconfig \
	PATH=$PATH:${EMSDK}:${EMSDK}/node/current/bin:${EMSDK}/upstream/emscripten:${SYSROOT_DIR}/bin:${PREFIX}/bin \
	EMSDK_NODE=${EMSDK}/node/current/bin/node \
	CPPFLAGS="-I${PREFIX}/include" \
	CFLAGS="-fPIC" \
	CXXFLAGS="-fPIC" \
	LDFLAGS="-L${PREFIX}/lib"

m4_include(`run-buildbot.m4')m4_dnl
