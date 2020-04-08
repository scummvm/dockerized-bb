# This toolchain is made of two sub-toolchains one for stable ScummVM and one for master one
# Two sub-toolchains are used to avoid invalidating one when updating the other
# The merging process, being only copies, is faster

FROM toolchains/common AS helpers

m4_include(`paths.m4')m4_dnl

# Don't import packages.m4 as it clashes with functions defined here

m4_define(`local_sdk_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)
m4_define(`local_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)
m4_define(`helpers_package', COPY --from=helpers /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)

##### master toolchain : NDK 21.0.6113669 + SDK licenses only / SDK and tools are download by Gradle #####
FROM debian:stable-slim AS toolchain-master
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

COPY functions-platform.sh lib-helpers/
COPY functions-sdk.sh lib-helpers/
COPY multi-build.sh lib-helpers/

# nasm is used for x86 ScummVM
# Create man directories to please openjdk which expects them
# cf. https://github.com/debuerreotype/debuerreotype/issues/10
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		default-jre-headless \
		golang-go \
		nasm && \
	rm -rf /var/lib/apt/lists/*

# API is the API versions for which we will compile packages
# This variable can also be :
# - all which means all API versions of all possible targets
# - lowest the lowest API version for each target
# - version[:version...] which will search for the specified versions (or most approaching) in all targets
#
# API and ANDROID_NDK_VERSION must be kept in sync with ScummVM source tree
# If multiple NDKs must be installed (for stable and master),
# we should duplicate all instructions from this point
#
# API is synchronized with ScummVM minSdkVersion
# As we follow same rules as Android, we should
# always get the same API versions as expected by Android

ENV ANDROID_ROOT=/opt/android/master

ENV ANDROID_NDK_ROOT=${ANDROID_ROOT}/ndk \
	ANDROID_NDK_VERSION=21.0.6113669 \
	API=16 \
	HOST_TAG=linux-x86_64

# Install NDK using settings above
local_sdk_package(ndk)

# Include the packaging instructions
m4_include(`packages_list.m4')

# Only install licenses on this version as everything will be installed by gradle
# It's installed last to avoid rebuilding everything if we just want to update licenses

ENV ANDROID_SDK_ROOT=${ANDROID_ROOT}/sdk
# Install SDK using settings above
local_sdk_package(sdk)

##### stable toolchain : NDK r14b and SDK 25 #####
FROM debian:stable-slim AS toolchain-stable
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

COPY functions-platform.sh lib-helpers/
# We don't need these functions for older SDK but that let's image reuse possible
COPY functions-sdk.sh lib-helpers/
COPY multi-build.sh lib-helpers/

# nasm is used for x86 ScummVM
# JDK is needed instead of JRE to patch Android SDK for OpenJDK 11
# Create man directories to please openjdk which expects them
# cf. https://github.com/debuerreotype/debuerreotype/issues/10
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		default-jdk-headless \
		golang-go \
		nasm && \
	rm -rf /var/lib/apt/lists/*

# Unlike the newer toolchain, this one is quite static because it shouldn't evolve in time
# and many tricks may depend on the NDK version

ENV ANDROID_ROOT=/opt/android/stable

# Old toolchains need python to create toolchains and old ncurses
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		libncurses5 \
		python && \
	rm -rf /var/lib/apt/lists/*

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
m4_include(`packages_list.m4')

# Install an old (unsupported) SDK because build process depends on android project command

ENV ANDROID_SDK_ROOT=${ANDROID_ROOT}/sdk
local_sdk_package(sdk-old)

##### Resulting toolchain #####
FROM debian:stable-slim
USER root

WORKDIR /usr/src

# Copy and execute each step separately to avoid invalidating cache
COPY --from=helpers /lib-helpers/prepare.sh lib-helpers/
RUN lib-helpers/prepare.sh

COPY --from=helpers /lib-helpers/functions.sh lib-helpers/

COPY functions-platform.sh lib-helpers/
COPY functions-sdk.sh lib-helpers/
COPY multi-build.sh lib-helpers/

# Create man directories to please openjdk which expects them
# cf. https://github.com/debuerreotype/debuerreotype/issues/10
# ant is used by ScummVM build system
# file is used ndk-build in NDK 14
# libncurses5 is used by binaries in NDK 14
# nasm is used for x86 ScummVM
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		ant \
		default-jre-headless \
		file \
		libncurses5 \
		nasm && \
	rm -rf /var/lib/apt/lists/*

ENV ANDROID_ROOT=/opt/android

# Toolchains are not (yet?) relocatable, so we must not change their path once they are compiled
COPY --from=toolchain-master ${ANDROID_ROOT}/master/ ${ANDROID_ROOT}/master/
COPY --from=toolchain-stable ${ANDROID_ROOT}/stable/ ${ANDROID_ROOT}/stable/
