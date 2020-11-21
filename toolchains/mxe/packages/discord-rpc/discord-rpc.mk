PKG             := discord-rpc
$(PKG)_WEBSITE  := https://github.com/discord/discord-rpc
$(PKG)_DESCR    := Discord RPC
$(PKG)_IGNORE   := 
$(PKG)_VERSION  := 3.4.0
$(PKG)_GH_CONF  := discord/discord-rpc/tags, v
$(PKG)_GH_ARCHIVE_EXT := .tar.gz
$(PKG)_CHECKSUM := e13427019027acd187352dacba6c65953af66fdf3c35fcf38fc40b454a9d7855
$(PKG)_DEPS     := cc rapidjson

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
        -DBUILD_SHARED_LIBS=$(CMAKE_SHARED_BOOL) \
	-DUSE_STATIC_CRT=$(CMAKE_SHARED_BOOL) \
	-DCMAKE_INSTALL_PREFIX='$(PREFIX)/$(TARGET)'

    '$(TARGET)-cmake' --build '$(BUILD_DIR)' --config Release --target install
endef

