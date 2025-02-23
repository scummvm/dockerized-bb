PKG             := fluidlite
$(PKG)_WEBSITE  := https://github.com/divideconcept/FluidLite
$(PKG)_DESCR    := Fluidlite
$(PKG)_IGNORE   := 
$(PKG)_VERSION  := b0f187b
$(PKG)_CHECKSUM := 44f240b0017eb76a5ae1b7c162d9199b0cb014f03f8bd863a56a980b101e6e88
$(PKG)_GH_CONF  := divideconcept/FluidLite/branches/master
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
	-DFLUIDLITE_BUILD_SHARED=OFF \
        $($(PKG)_CONFIGURE_OPTS)
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' VERBOSE=1
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install VERBOSE=1
endef
