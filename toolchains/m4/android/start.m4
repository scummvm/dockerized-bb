m4_define(`local_sdk_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`local_package', COPY packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`helpers_package', COPY --from=helpers /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)m4_dnl
m4_define(`android_package', COPY --from=android-helpers /lib-helpers/packages/$1 lib-helpers/packages/$1/
RUN $3 lib-helpers/multi-build.sh lib-helpers/packages/$1/build.sh $2)

FROM toolchains/android-common AS android-helpers

m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_include(`debian-toolchain-base.m4')m4_dnl

COPY --from=android-helpers /lib-helpers/functions-platform.sh \
	/lib-helpers/multi-build.sh lib-helpers/

# nasm is used for x86 ScummVM
# Create man directories to please openjdk which expects them
# cf. https://github.com/debuerreotype/debuerreotype/issues/10
# python3-protobuf is needed to generate DLC packs
RUN for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		default-jre-headless \
		nasm \
		python3-protobuf && \
	rm -rf /var/lib/apt/lists/*

# Copy functions-sdk.sh after because it contains version information
COPY --from=android-helpers /lib-helpers/functions-sdk.sh lib-helpers/
