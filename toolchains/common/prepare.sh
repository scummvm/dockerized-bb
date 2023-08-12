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
	python3 \
	python-is-python3 \
	quilt \
	unzip \
	vim \
	wget
rm -rf /var/lib/apt/lists/*

sed 's/^Types: deb$/Types: deb-src/' /etc/apt/sources.list.d/debian.sources \
		> /etc/apt/sources.list.d/debian-src.sources

if [ -f "$HELPERS_DIR"/prepare-platform.sh ]; then
	. "$HELPERS_DIR"/prepare-platform.sh
fi
