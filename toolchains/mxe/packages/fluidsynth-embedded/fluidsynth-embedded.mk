PKG             := fluidsynth-embedded
$(PKG)_WEBSITE  := $(fluidsynth_WEBSITE)
$(PKG)_DESCR    := FluidSynth (with embedded OSAL)
$(PKG)_IGNORE   := $(fluidsynth_IGNORE)
$(PKG)_VERSION  := 2.5.0
$(PKG)_CHECKSUM := e4ae831ce02f38b5594ab4dacb11c1a4067ca65ea183523655ebdc9c1b2b92a1
$(PKG)_GH_CONF  := $(fluidsynth_GH_CONF)
$(PKG)_FILE     := fluidsynth-$$(filter-out $$(PKG)-,$$($$(PKG)_TAG_PREFIX))$($(PKG)_VERSION)$$($$(PKG)_TAG_SUFFIX)$$($$(PKG)_ARCHIVE_EXT)
$(PKG)_DEPS     := cc mman-win32 gcem

# Use test file and patches provided by MXE
$(PKG)_TEST_FILE = $(fluidsynth_TEST_FILE)

$(PKG)_BUILD = $(fluidsynth_BUILD)
$(eval define $(PKG)_BUILD$(newline)\
	  $(subst -gcc,-g++,$(value fluidsynth_BUILD))$(newline)\
	  endef)
$(PKG)_CONFIGURE_OPTS = \
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
	-Denable-framework=off

# Don't remove following comment: it's used to trigger automatic detection of cmake based packages
# We could manually add dependency but if it changes, we could expect that heuristic won't
# $(TARGET)-cmake
