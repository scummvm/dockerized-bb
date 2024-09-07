##### New toolchain : NDK + SDK licenses only / SDK and tools are downloaded by Gradle #####
m4_include(`android/start.m4')m4_dnl

# Newer SDKs need Go
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		golang-go && \
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

ENV ANDROID_ROOT=/opt/android

ENV ANDROID_NDK_ROOT=${ANDROID_ROOT}/ndk \
	ANDROID_NDK_VERSION=23.2.8568313 \
	API=16 \
	HOST_TAG=linux-x86_64

# Install NDK using settings above
local_sdk_package(ndk)

# Include the packaging instructions
m4_include(`android/packages_list.m4')

# Only install licenses on this version as everything will be installed by gradle
# It's installed last to avoid rebuilding everything if we just want to update licenses

ENV ANDROID_SDK_ROOT=${ANDROID_ROOT}/sdk
# Install SDK using settings above
local_sdk_package(sdk)

define_aliases(android-arm-v7a, androiddistdebug, , , arm)
define_aliases(android-arm64-v8a, androiddistdebug, , , arm64)
define_aliases(android-x86, androiddistdebug, , , x86)
define_aliases(android-x86_64, androiddistdebug, , , x86_64)
