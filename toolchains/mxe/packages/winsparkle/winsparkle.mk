# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := winsparkle
$(PKG)_WEBSITE  := https://winsparkle.org/
$(PKG)_DESCR    := WinSparkle
$(PKG)_IGNORE   := 
$(PKG)_VERSION  := 0.9.2
$(PKG)_GH_CONF  := vslavik/winsparkle/tags, v
$(PKG)_CHECKSUM := 2a5facf5a22056edf7afc4d0a4bf05620b7aa7cc1619c3078b281e374cdb9996
$(PKG)_SUBDIR   := WinSparkle-$($(PKG)_VERSION)
$(PKG)_FILE     := WinSparkle-$($(PKG)_VERSION).zip
$(PKG)_URL      := https://github.com/vslavik/winsparkle/releases/download/v$($(PKG)_VERSION)/$($(PKG)_FILE)
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    mkdir -p '$(PREFIX)/$(TARGET)/include/' '$(PREFIX)/$(TARGET)/bin/' '$(PREFIX)/$(TARGET)/lib'

    cp '$(SOURCE_DIR)'/include/* '$(PREFIX)/$(TARGET)/include/'
    cp '$(SOURCE_DIR)'/bin/* '$(PREFIX)/$(TARGET)/bin/'
    cp '$(SOURCE_DIR)/$(if $(findstring x86_64,$(TARGET)),x64/Release,Release)'/*.lib '$(PREFIX)/$(TARGET)/lib'
    cp '$(SOURCE_DIR)/$(if $(findstring x86_64,$(TARGET)),x64/Release,Release)'/*.dll '$(PREFIX)/$(TARGET)/bin'
endef
