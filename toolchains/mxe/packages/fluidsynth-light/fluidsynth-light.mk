# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := fluidsynth-light
$(PKG)_WEBSITE  := http://fluidsynth.org/
$(PKG)_DESCR    := FluidSynth (with less deps)
$(PKG)_IGNORE   = $(fluidsynth_IGNORE)
$(PKG)_VERSION  = $(fluidsynth_VERSION)
$(PKG)_CHECKSUM = $(fluidsynth_CHECKSUM)
$(PKG)_GH_CONF  := $(fluidsynth_GH_CONF)
$(PKG)_SUBDIR   = $(fluidsynth_SUBDIR)
$(PKG)_FILE     = $(fluidsynth_FILE)
$(PKG)_URL      = $(fluidsynth_URL)
$(PKG)_DEPS     := cc glib-light

$(PKG)_OO_DEPS += cmake-conf

# Use test file and patches provided by MXE
$(PKG)_TEST_FILE = $(fluidsynth_TEST_FILE)
$(PKG)_PATCHES = $(fluidsynth_PATCHES)

define $(PKG)_UPDATE
    echo $(fluidsynth_VERSION)
endef

$(PKG)_BUILD = $(fluidsynth_BUILD)
$(PKG)_CONFIGURE_OPTS = -Denable-aufile=OFF -Denable-dbus=OFF \
    -Denable-network=OFF -Denable-jack=OFF \
    -Denable-ladspa=OFF -Denable-libinstpatch=OFF \
    -Denable-libsndfile=OFF -Denable-midishare=OFF \
    -Denable-opensles=OFF -Denable-oboe=OFF \
    -Denable-oss=OFF -Denable-dsound=OFF \
    -Denable-waveout=OFF -Denable-winmidi=OFF \
    -Denable-sdl2=OFF -Denable-pulseaudio=OFF \
    -Denable-readline=OFF

# Don't remove following comment: it's used to trigger automatic detection of cmake based packages
# We could manually add dependency but if it changes, we could expect that heuristic won't
# $(TARGET)-cmake
