#! /bin/sh

# Stick with toolchain version
FLUIDSYNTH_VERSION=1.1.6

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch fluidsynth \
	"https://github.com/FluidSynth/fluidsynth/archive/v${FLUIDSYNTH_VERSION}.tar.gz" 'tar xzf'

cd fluidsynth

# Don't install fluidsynth binary
# Still build it to ensure we have a working setup
sed -i -e 's/install\(.*\) fluidsynth /install\1 /g' src/CMakeLists.txt

do_cmake \
	-DBUILD_SHARED_LIBS=yes \
	-DCMAKE_BUILD_TYPE=Release -Denable-floats=on \
	-Denable-alsa=on -Denable-libsndfile=on \
	-Denable-dbus=off -DCMAKE_DISABLE_FIND_PACKAGE_OSS=TRUE \
	-Denable-pulseaudio=off -Denable-readline=off

do_make
do_make install

do_clean_bdir
