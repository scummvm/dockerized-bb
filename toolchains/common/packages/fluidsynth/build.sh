#! /bin/sh

FLUIDSYNTH_VERSION=2.2.9

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_pkg_fetch libffi

do_configure --disable-builddir
do_make
# Install only includes and library (no man pages, nor info)
do_make -C include install
do_make install-pkgconfigDATA install-toolexeclibLTLIBRARIES

cd ..

do_pkg_fetch gettext

autoreconf -vfi

do_configure --disable-libasprintf --disable-java --disable-c++
# No binaries, no man, ...
do_make -C gettext-runtime/intl
do_make -C gettext-runtime/intl install

cd ..

do_pkg_fetch glib2.0
do_patch glib

# Only keep glib and gthread
sed -i -e "/subdir('/{/'glib'/n; /'gthread'/n; s/^/#/}" meson.build

do_meson
ninja
ninja install

# We are in build directory
cd ../..

# Debian version is quite old
do_http_fetch fluidsynth \
	"https://github.com/FluidSynth/fluidsynth/archive/v${FLUIDSYNTH_VERSION}.tar.gz" 'tar xzf'

# Fluidsynth doesn't link correctly against static glib, fix this
sed -i -e 's/\${GLIB_\([^}]\+\)}/${GLIB_STATIC_\1}/g' CMakeLists.txt src/CMakeLists.txt
sed -i -e '/add_executable ( fluidsynth/,/)/{
/)/a target_link_options ( fluidsynth PRIVATE ${GLIB_STATIC_LDFLAGS_OTHER} )
}' src/CMakeLists.txt
# Don't install fluidsynth binary
# Still build it to ensure we have a working setup with all static libraries
sed -i -e 's/install\(.*\) fluidsynth /install\1 /g' src/CMakeLists.txt

# -DCMAKE_SYSTEM_NAME=Windows for Windows

# Lighten Fluidsynth the most we can
do_cmake \
	-Denable-aufile=off -Denable-dbus=off \
	-Denable-network=off -Denable-jack=off \
	-Denable-ladspa=off -Denable-libinstpatch=off \
	-Denable-libsndfile=off -Denable-midishare=off \
	-Denable-opensles=off -Denable-oboe=off \
	-Denable-oss=off -Denable-dsound=off \
	-Denable-waveout=off -Denable-winmidi=off \
	-Denable-sdl2=off -Denable-pulseaudio=off \
	-Denable-readline=off -Denable-lash=off \
	-Denable-alsa=off -Denable-systemd=off \
	-Denable-coreaudio=off -Denable-coremidi=off \
	-Denable-framework=off -Denable-dart=off "$@"
do_make
do_make install

do_clean_bdir
