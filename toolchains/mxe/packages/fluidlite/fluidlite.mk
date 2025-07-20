PKG             := fluidlite
$(PKG)_WEBSITE  := https://github.com/divideconcept/FluidLite
$(PKG)_DESCR    := Fluidlite
$(PKG)_IGNORE   := 
$(PKG)_VERSION  := 4a01cf1
$(PKG)_CHECKSUM := e0f7b6789021ef55c6f51ca5b82a1f9274564b4936ae6960f5db64ff4d6ef1ea
$(PKG)_GH_CONF  := divideconcept/FluidLite/branches/master
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
	-DFLUIDLITE_BUILD_SHARED=OFF \
        $($(PKG)_CONFIGURE_OPTS)
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' VERBOSE=1
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install VERBOSE=1
endef
