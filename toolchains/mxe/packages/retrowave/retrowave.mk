PKG             := retrowave
$(PKG)_WEBSITE  := https://github.com/SudoMaker/RetroWave
$(PKG)_DESCR    := RetroWave
$(PKG)_IGNORE   := 
$(PKG)_VERSION  := 0.0.9
$(PKG)_GH_CONF  := SudoMaker/RetroWave/tags, v
$(PKG)_GH_ARCHIVE_EXT := .tar.gz
$(PKG)_CHECKSUM := 720704b062e6292aa4d3c7b10413d32902b1021d1212311e29f48eca9f6ab101
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
        -DCMAKE_INSTALL_PREFIX='$(PREFIX)/$(TARGET)' \
	-DBUILD_SHARED_LIBS=FALSE \
	-DRETROWAVE_BUILD_PLAYER=0

    '$(TARGET)-cmake' --build '$(BUILD_DIR)' --config Release --target install
endef
