PKG             := retrowave
$(PKG)_WEBSITE  := https://github.com/SudoMaker/RetroWave
$(PKG)_DESCR    := RetroWave
$(PKG)_IGNORE   := 
$(PKG)_VERSION  := 0.1.0
$(PKG)_GH_CONF  := SudoMaker/RetroWave/tags, v
$(PKG)_GH_ARCHIVE_EXT := .tar.gz
$(PKG)_CHECKSUM := da86c0ecfde558da6a01e5f6d1d0c6a07a164ef5cff912f7a8667089adf7ea84
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
        -DCMAKE_INSTALL_PREFIX='$(PREFIX)/$(TARGET)' \
	-DBUILD_SHARED_LIBS=FALSE \
	-DRETROWAVE_BUILD_PLAYER=0

    '$(TARGET)-cmake' --build '$(BUILD_DIR)' --config Release --target install
endef
