FROM toolchains/android-old AS toolchain

m4_include(`debian-builder-base.m4')m4_dnl

# nasm is used for x86 ScummVM
# Create man directories to please openjdk which expects them
# cf. https://github.com/debuerreotype/debuerreotype/issues/10
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		default-jre-headless \
		nasm && \
	rm -rf /var/lib/apt/lists/*

# Split to keep the previous rule the same as the android one
# Ant is needed by old Android build system
# file is needed by ndk-build
# libncurses5 is needed by all binaries
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		ant \
		file \
		libncurses5 && \
	rm -rf /var/lib/apt/lists/*

ENV RO_ANDROID_ROOT=/opt/android \
	ANDROID_EXTERNAL_ROOT=/data/bshomes/android \
	HOST_TAG=linux-x86_64

COPY --from=toolchain ${RO_ANDROID_ROOT} ${RO_ANDROID_ROOT}/

# Copy the wrapper script in charge of copying the licenses at the right place
COPY setup_wrapper.sh ${RO_ANDROID_ROOT}/

ENV ANDROID_NDK=${RO_ANDROID_ROOT}/ndk \
	ANDROID_TOOLCHAIN=${RO_ANDROID_ROOT}/toolchain \
	ANDROID_SDK=${RO_ANDROID_ROOT}/sdk \
	ANDROID_SDK_HOME=${ANDROID_EXTERNAL_ROOT}/sdk-home

# Don't forget quotes for the ENTRYPOINT as it's a list of strings
# We can't use RO_ANDROID_ROOT there as it's not expanded when running
m4_define(`ENTRY_WRAPPER', `"/opt/android/setup_wrapper.sh"')m4_dnl
m4_include(`run-buildbot.m4')m4_dnl
