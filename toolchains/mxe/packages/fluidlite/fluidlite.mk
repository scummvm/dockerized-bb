PKG             := fluidlite
$(PKG)_WEBSITE  := https://github.com/divideconcept/FluidLite
$(PKG)_DESCR    := Fluidlite
$(PKG)_IGNORE   := 
$(PKG)_VERSION  := d59d232
$(PKG)_CHECKSUM := f119ff09fa7e3a87874eb51546de66ce50342bbefd9ab11e37f292a71b097c5e
$(PKG)_GH_CONF  := divideconcept/FluidLite/branches/master
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
	-DFLUIDLITE_BUILD_SHARED=OFF \
        $($(PKG)_CONFIGURE_OPTS)
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' VERBOSE=1
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install VERBOSE=1
endef
