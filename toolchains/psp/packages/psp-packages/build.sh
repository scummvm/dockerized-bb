#! /bin/sh

PSP_PACKAGES_VERSION=6651ea449d32544bd0e110a53348437ea001ba27

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch psp-packages "https://github.com/pspdev/psp-packages/archive/${PSP_PACKAGES_VERSION}.tar.gz" 'tar xzf'

# Patch to drop privileges during the build
sed -i -e 's|psp-makepkg|su nobody -s /bin/sh -c "env PATH=\"\$PATH:$PSPDEV/bin\" psp-makepkg"|' ./build.sh

# Give rights to nobody
chmod -R go+rwX .

# Let psp-pacman believe it can do anything
chmod o+w "$PSPDEV"

# To let build.sh find psp-pacman
export PATH="$PATH:$PSPDEV/bin"

# One argument with the whole list
MAKEFLAGS="-d -j16" ./build.sh --install "$*"

# Restore the rights
chmod o-w "$PSPDEV"

# Patch pc files to ensure they have proper paths
badprefix="$(pwd)/[^/]\\+/pkg/[^/]\\+/psp"

PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR:-${PREFIX}/lib/pkgconfig:${PREFIX}/share/pkgconfig}
echo "$PKG_CONFIG_LIBDIR" | tr ':' '\n' | while read p; do
	for f in "$p"/*; do
		if [ "$f" = "$p/*" -o ! -f "$f" ]; then
			continue
		fi
		sed -i -e "s|${badprefix}|${PREFIX}|" "$f"
	done
done

do_clean_bdir

# Cleanup wget HSTS
rm -f $HOME/.wget-hsts
