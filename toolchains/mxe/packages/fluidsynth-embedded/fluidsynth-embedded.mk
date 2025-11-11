PKG             := fluidsynth-embedded
$(PKG)_WEBSITE  := $(fluidsynth_WEBSITE)
$(PKG)_DESCR    := FluidSynth (with embedded OSAL)
$(PKG)_IGNORE   := $(fluidsynth_IGNORE)
$(PKG)_VERSION  := 2.5.1
$(PKG)_CHECKSUM := 10b2e32ba78c72ac1384965c66df06443a4bd0ab968dcafaf8fa17086001bf03
$(PKG)_GH_CONF  := $(fluidsynth_GH_CONF)
$(PKG)_FILE     := fluidsynth-$$(filter-out $$(PKG)-,$$($$(PKG)_TAG_PREFIX))$($(PKG)_VERSION)$$($$(PKG)_TAG_SUFFIX)$$($$(PKG)_ARCHIVE_EXT)
$(PKG)_DEPS     := cc mman-win32 gcem

# Use test file and patches provided by MXE
$(PKG)_TEST_FILE = $(fluidsynth_TEST_FILE)

$(PKG)_BUILD = $(fluidsynth_BUILD)
$(PKG)_CONFIGURE_OPTS = \
	-Denable-native-dls=on \
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

define $(PKG)_BUILD
    # Disable tests and docs
    $(SED) -i -e 's/add_subdirectory *( *\(test\|doc\) *)/# \0/' '$(SOURCE_DIR)/CMakeLists.txt'
    $(if $(BUILD_STATIC), $(SED) -i -e '/generate_pkgconfig_spec/i list( APPEND PC_LIBS_PRIV "-lstdc++")' '$(SOURCE_DIR)/CMakeLists.txt')
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
        -Dosal=embedded \
        $($(PKG)_CONFIGURE_OPTS)
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' VERBOSE=1
    '$(TARGET)-cmake' --install '$(BUILD_DIR)' --component fluidsynth_runtime
    '$(TARGET)-cmake' --install '$(BUILD_DIR)' --component fluidsynth_development

    # compile test
    '$(TARGET)-gcc' \
        -W -Wall -Werror -ansi -pedantic \
        -Wl,--allow-multiple-definition \
        '$(TEST_FILE)' -o '$(PREFIX)/$(TARGET)/bin/test-fluidsynth.exe' \
        `'$(TARGET)-pkg-config' --cflags --libs fluidsynth`
endef

# Don't remove following comment: it's used to trigger automatic detection of cmake based packages
# We could manually add dependency but if it changes, we could expect that heuristic won't
# $(TARGET)-cmake
