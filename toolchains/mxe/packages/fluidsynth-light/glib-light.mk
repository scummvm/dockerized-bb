# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := glib-light
$(PKG)_WEBSITE  := https://gtk.org/
$(PKG)_DESCR    := Minimal GLib (for FluidSynth only)
$(PKG)_IGNORE   = $(glib_IGNORE)
$(PKG)_VERSION  = $(glib_VERSION)
$(PKG)_CHECKSUM = $(glib_CHECKSUM)
$(PKG)_SUBDIR   = $(glib_SUBDIR)
$(PKG)_FILE     = $(glib_FILE)
$(PKG)_URL      = $(glib_URL)
$(PKG)_DEPS     := cc gettext libffi

# Use patches provided by MXE
$(PKG)_PATCHES = $(glib_PATCHES)

define $(PKG)_UPDATE
    echo $(glib_VERSION)
endef

define $(PKG)_BUILD
    # cross build
    # Prevent autogen to override GTKDOCIZE which is used by autoreconf
    sed -i -e 's/GTKDOCIZE/GTKDOCIZE_/' $(SOURCE_DIR)/autogen.sh
    cd '$(SOURCE_DIR)' && NOCONFIGURE=true GTKDOCIZE=true ./autogen.sh
    cd '$(BUILD_DIR)' && '$(SOURCE_DIR)/configure' \
        $(MXE_CONFIGURE_OPTS) \
        --with-threads=win32 \
        --with-pcre=internal \
        CXX='$(TARGET)-g++' \
        PKG_CONFIG='$(PREFIX)/bin/$(TARGET)-pkg-config' \
	CFLAGS='-Wno-incompatible-pointer-types -Wno-deprecated-declarations -Wno-format'
    $(MAKE) -C '$(BUILD_DIR)/glib'    -j '$(JOBS)' install sbin_PROGRAMS= noinst_PROGRAMS=
    $(MAKE) -C '$(BUILD_DIR)/gthread' -j '$(JOBS)' install bin_PROGRAMS= sbin_PROGRAMS= noinst_PROGRAMS=
    $(MAKE) -C '$(BUILD_DIR)'         -j '$(JOBS)' install-pkgconfigDATA pkgconfig_DATA="glib-2.0.pc gthread-2.0.pc"
endef

