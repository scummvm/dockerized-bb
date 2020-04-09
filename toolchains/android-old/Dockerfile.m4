##### Old toolchain : NDK r14b and SDK 25 #####
m4_include(`android/start.m4')m4_dnl

# Ant is needed by old Android build system
# file and python are needed by NDK
# libncurses5 is needed by all binaries
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		ant \
		file \
		libncurses5 \
		python && \
	rm -rf /var/lib/apt/lists/*

# Unlike the newer toolchain, this one is quite static because it shouldn't evolve in time
# and many tricks may depend on the NDK version

ENV ANDROID_ROOT=/opt/android

# ABIS is for ndk-old package and determine how the unified toolchain will be composed
# API is none because we don't have new style folder hierarchy
ENV ANDROID_NDK_ROOT=${ANDROID_ROOT}/ndk \
	TOOLCHAIN=${ANDROID_ROOT}/toolchain \
	ABIS="arm/9 arm64/21 x86/9 x86_64/21" \
	API="none" \
	HOST_TAG=linux-x86_64

# Install NDK using settings above
local_sdk_package(ndk-old)

# Include the packaging instructions
m4_include(`android/packages_list.m4')

# Install an old (unsupported) SDK because build process depends on android project command
ENV ANDROID_SDK_ROOT=${ANDROID_ROOT}/sdk
local_sdk_package(sdk-old)
