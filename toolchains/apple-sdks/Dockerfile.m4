m4_include(`packages.m4')m4_dnl
m4_dnl Include Debian base preparation steps
m4_dnl This ensures all common steps are shared by all toolchains
m4_define(`STAGE_IMAGE_NAME',extractor)
m4_include(`debian-toolchain-base.m4')m4_dnl

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		cpio \
		libbz2-dev \
		liblzma-dev \
		libxml2-dev \
		libssl-dev \
		zlib1g-dev \
		&& \
	rm -rf /var/lib/apt/lists/*

ENV SDK_DIR=/opt/sdk

ENV PACKAGES_LOCATION=/opt/

m4_dnl Use a define to have only one place to change
m4_define(`I386_XCODE_VERSION', 9.4.1)
# Extract last MacOS X SDK supporting i686 builds
COPY Xcode_`'I386_XCODE_VERSION.xip* ${PACKAGES_LOCATION}
local_package(xcode-extractor, , PACKAGE=Xcode_`'I386_XCODE_VERSION.xip SDK_PLATFORMS="MacOSX")

# Extract latest MacOS X and iPhoneOS SDK
m4_define(`XCODE_VERSION', 13.0)
COPY Xcode_`'XCODE_VERSION.xip* ${PACKAGES_LOCATION}
local_package(xcode-extractor, , PACKAGE=Xcode_`'XCODE_VERSION.xip SDK_PLATFORMS="MacOSX iPhoneOS")

FROM scratch

COPY --from=extractor /opt/sdk/* /sdk/
