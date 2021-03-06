#! /bin/sh

# Stick with toolchain version
GLIB2_VERSION=2.38.2
GLIB2_SHA256=056a9854c0966a0945e16146b3345b7a82562a5ba4d5516fd10398732aea5734

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch glib "http://ftp.gnome.org/pub/gnome/sources/glib/${GLIB2_VERSION%.*}/glib-${GLIB2_VERSION}.tar.xz" 'tar xJf' "sha256:${GLIB2_SHA256}"

NOCONFIGURE=1 ./autogen.sh

cd ..

# Compile on host for tools
mkdir host-glib
cd host-glib

# Spawn a subshell to clear environment for native build without loosing it
(
unset ACLOCAL_PATH AR AS CC CPP CXX CXXFILT GCC LD NM OBJCOPY OBJDUMP PKG_CONFIG_LIBDIR RANLIB READELF STRINGS STRIP
../glib*/configure --prefix="$(pwd)/prefix"
)

do_make
do_make install

export PATH="$PATH:$(pwd)/prefix/bin"

cd ..

cd glib*/

# We must export because sh keeps local to functions the variables assignments put in front of them
export ac_cv_func_posix_getpwuid_r=yes ac_cv_func_posix_getgrgid_r=no glib_cv_stack_grows=no glib_cv_uscore=no
do_configure_shared --disable-modular-tests \
	--with-libiconv=gnu \
	--with-pcre=internal
unset ac_cv_func_posix_getpwuid_r ac_cv_func_posix_getgrgid_r glib_cv_stack_grows glib_cv_uscore

# Build and install only the bare minimum for fluidsynth
do_make -C glib
do_make -C gthread
do_make -C glib install
do_make -C gthread install
do_make install-pkgconfigDATA pkgconfig_DATA="glib-2.0.pc gthread-2.0.pc"

do_clean_bdir
