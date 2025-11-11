#! /bin/sh

FLUIDSYNTH_VERSION=2.5.1

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# Debian version doesn't support the embedded OS abstraction layer
do_http_fetch fluidsynth \
	"https://github.com/FluidSynth/fluidsynth/archive/v${FLUIDSYNTH_VERSION}.tar.gz" 'tar xzf'

# -DCMAKE_SYSTEM_NAME=Windows for Windows

# Lighten Fluidsynth the most we can
# DLS support will be enabled only if C++17 is available
do_cmake \
	-Dosal=embedded -Denable-native-dls=on \
	-Denable-alsa=off -Denable-aufile=off \
	-Denable-dbus=off -Denable-jack=off \
	-Denable-ladspa=off -Denable-libinstpatch=off \
	-Denable-libsndfile=off -Denable-midishare=off \
	-Denable-opensles=off -Denable-oboe=off \
	-Denable-network=off -Denable-oss=off \
	-Denable-dsound=off -Denable-wasapi=off \
	-Denable-waveout=off -Denable-winmidi=off \
	-Denable-sdl3=off -Denable-pulseaudio=off \
	-Denable-pipewire=off -Denable-readline=off \
	-Denable-threads=off -Denable-openmp=off \
	-Denable-systemd=off \
	-Denable-coreaudio=off -Denable-coremidi=off \
	-Denable-framework=off \
	"$@"
do_make
cmake --install . --component fluidsynth_runtime
cmake --install . --component fluidsynth_development

do_clean_bdir
