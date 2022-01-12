#! /bin/sh

HELPERS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

set -e
set -x

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	automake \
	ca-certificates \
	cmake \
	curl \
	debhelper \
	dpkg-dev \
	git \
	gnupg \
	less \
	libtool \
	make \
	meson \
	pkg-config \
	quilt \
	unzip \
	vim \
	wget
rm -rf /var/lib/apt/lists/*

sed 's/^deb \(.*\)/deb-src \1/' /etc/apt/sources.list \
		> /etc/apt/sources.list.d/debsrc.list

if [ -f "$HELPERS_DIR"/prepare-platform.sh ]; then
	. "$HELPERS_DIR"/prepare-platform.sh
fi
