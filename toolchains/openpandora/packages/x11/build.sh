#! /bin/sh

# Use same versions as OpenPandora toolchain
UTIL_MACROS_VERSION=1.7.0
UTIL_MACROS_SHA256=7a5519ca22cd6bc4664be7b52cc58d5594e9f18c282ee0f6f7c59c1dffabdd13

BIGREQSPROTO_VERSION=1.1.0
BIGREQSPROTO_SHA256=000703ba64664bd9018af88192062e7df8da30ed1939b4e7cbfd68baaa966390

KBPROTO_VERSION=1.0.4
KBPROTO_SHA256=d7fcd4fa4332109b05f0d5e238e4aa0ef2ca1a51b45ab9fcf8affd7ee021cfe7

INPUTPROTO_VERSION=2.0
INPUTPROTO_SHA256=cd89a1e95745875e66947ba28587c720c91aec63836ac6548ca12fd525c0a2ee

RANDRPROTO_VERSION=1.3.1
RANDRPROTO_SHA256=cdabd4d78b58ce4fd173793edc53d64e568f54da479e9b93e7c68185555af86f

RENDERPROTO_VERSION=0.11
RENDERPROTO_SHA256=256e4af1d3b4007872a276ed9e5c2522f80f5fe69b97268542917635b4dbf758

XCMISCPROTO_VERSION=1.2.0
XCMISCPROTO_SHA256=3e7ebffc1cdf93b371aa0db90775a630f66c3a77815059992c7b2789f119273e

XEXTPROTO_VERSION=7.1.1
XEXTPROTO_SHA256=5ade284271eed437b05829be336b2b0ddaabad48335be220c0d9d5101fd8baec

XF86BIGFONTPROTO_VERSION=1.2.0
XF86BIGFONTPROTO_SHA256=d190e6462b2bbbac6ee9a007fb8eccb9ad9f5f70544154f388266f031d4bbb23

XPROTO_VERSION=7.0.16
XPROTO_SHA256=996eb41d9ec3ddcea503f12230ea5fbb8ca36a9fa9facb241dacf063468d9972

XTRANS_VERSION=1.2.5
XTRANS_SHA256=97d76ab76c755fabf2ef1896aaa76c0e38fc58d92799f9b2dd885a535cdd1e2b

LIBXAU_VERSION=1.0.5
LIBXAU_SHA256=2ad4324cf204331d6773bba441baed58e46168e7913de2079f10b272eae5c4db

LIBXDMCP_VERSION=1.0.3
LIBXDMCP_SHA256=ac6fb3182d50c5e2b1723a09eb77593602a7e64d7d501ea90a79edc26acb87b2

LIBX11_VERSION=1.3.3
LIBX11_SHA256=91274846aebcc9b1867d051c87833ef8f1a1ebe372b675373dd2a744360a8734

LIBXEXT_VERSION=1.1.1
LIBXEXT_SHA256=e3149cffe6f26ec1fe5022bc582e8621cc26d718b6d712c79b4619af39812db9

LIBXRENDER_VERSION=0.9.5
LIBXRENDER_SHA256=1f8b12a94ede6d5c9c7f34a137da9f88504ae16b69f76d03e429e2920c840a20

LIBXRANDR_VERSION=1.3.0
LIBXRANDR_SHA256=c2a7cfeb8506734bca4c23321c1ba5d9e6f9b1bd2f2434033a6bd9eea6814b7a

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

BDIR=$(pwd)

do_xorg_fetch () {
	cd "$BDIR"

	varname=$(echo $2 | tr a-z- A-Z_)
	eval "local pkg_VERSION=\$${varname}_VERSION"
	eval "local pkg_SHA256=\$${varname}_SHA256"

	do_http_fetch $2 "https://www.x.org/releases/individual/$1/$2-$pkg_VERSION.tar.gz" \
		'tar xzf' "sha256:$pkg_SHA256"
}

# util-macros
do_xorg_fetch util util-macros

# Patch pkg-config directory
sed -ie 's/^\(pkgconfigdir .*\)\$(datadir)/\1$(libdir)/' Makefile.in

do_configure_shared
do_make
do_make install

# bigreqsproto
do_xorg_fetch proto bigreqsproto
do_configure_shared
do_make
do_make install

# kbproto
do_xorg_fetch proto kbproto
do_configure_shared
do_make
do_make install

# inputproto
do_xorg_fetch proto inputproto
do_configure_shared
do_make
do_make install

# randrproto
do_xorg_fetch proto randrproto
do_configure_shared
do_make
# No doc
do_make install-pkgconfigDATA \
	install-randrHEADERS

# renderproto
do_xorg_fetch proto renderproto
do_configure_shared
do_make
do_make install-pkgconfigDATA \
	install-renderHEADERS

# xcmiscproto
do_xorg_fetch proto xcmiscproto
do_configure_shared
do_make
do_make install

# xextproto
do_xorg_fetch proto xextproto
do_configure_shared
do_make
do_make install

# xf86bigfontproto
do_xorg_fetch proto xf86bigfontproto
do_configure_shared
do_make
do_make install

# xproto
do_xorg_fetch proto xproto
do_configure_shared
do_make
do_make install

# xtrans
do_xorg_fetch lib xtrans

# Patch pkg-config directory
sed -ie 's/^\(pkgconfigdir .*\)\$(datadir)/\1$(libdir)/' Makefile.in

do_configure_shared --disable-docs
do_make
# No docs
do_make install-XtransincludeHEADERS \
	install-aclocalDATA \
	install-pkgconfigDATA

# libXau
do_xorg_fetch lib libXau
do_configure_shared
do_make
do_make install-libLTLIBRARIES \
	install-pkgconfigDATA \
	install-xauincludeHEADERS

# libXdmcp
do_xorg_fetch lib libXdmcp
do_configure_shared
do_make
do_make install-libLTLIBRARIES \
	install-pkgconfigDATA \
	install-xdmcpincludeHEADERS

# libX11
do_xorg_fetch lib libX11
do_configure_shared --without-xcb
do_make

# Just install the bare minimum
do_make install-pkgconfigDATA
do_make -C src install
do_make -C include install

# libXext
do_xorg_fetch lib libXext
do_configure_shared --disable-malloc0returnsnull
do_make

# No man pages
do_make install-pkgconfigDATA
do_make -C src install-libLTLIBRARIES \
	install-libXextincludeHEADERS

# libXrender
do_xorg_fetch lib libXrender
do_configure_shared --disable-malloc0returnsnull
do_make

# No man pages
do_make -C src install
do_make install-pkgconfigDATA

# libXrandr
do_xorg_fetch lib libXrandr
do_configure_shared --disable-malloc0returnsnull
do_make

# No man pages
do_make -C src install
do_make install-pkgconfigDATA

do_clean_bdir
