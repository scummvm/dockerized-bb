PKG             := rapidjson
$(PKG)_WEBSITE  := https://github.com/Tencent/rapidjson
$(PKG)_IGNORE   := 
$(PKG)_VERSION  := 1.1.0
$(PKG)_GH_CONF  := Tencent/rapidjson/tags, v
$(PKG)_GH_ARCHIVE_EXT := .tar.gz
$(PKG)_CHECKSUM := bf7ced29704a1e696fbccf2a2b4ea068e7774fa37f6d7dd4039d0787f8bed98e
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
	-DRAPIDJSON_BUILD_DOC=OFF \
	-DRAPIDJSON_BUILD_EXAMPLES=OFF \
	-DRAPIDJSON_BUILD_TESTS=OFF \
	-DCMAKE_INSTALL_PREFIX='$(PREFIX)/$(TARGET)'

    $(MAKE) -C '$(BUILD_DIR)' -j 1 install
endef
