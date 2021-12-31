m4_include(`paths.m4')m4_dnl

m4_include(`debian-builder-base.m4')m4_dnl

m4_include(`debian-libraries.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		clang \
		lld \
		llvm \
                && \
        rm -rf /var/lib/apt/lists/*

# We add PATH here for *-config and platform specific binaries
# llvm-dwp isn't compatible with binutils one and we don't invoke it correctly
ENV \
	def_binaries(`/usr/bin/llvm-', `ar, as, cxxfilt, nm, objcopy, objdump, ranlib, readelf, strings, strip') \
	def_binaries(`/usr/bin/', `clang, clang++') \
	CC=/usr/bin/clang \
	CXX=/usr/bin/clang++ \
	DWP=/usr/bin/dwp \
	LD=/usr/bin/lld

m4_include(`run-buildbot.m4')m4_dnl
