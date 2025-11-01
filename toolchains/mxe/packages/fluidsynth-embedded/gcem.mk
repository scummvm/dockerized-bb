PKG             := gcem
$(PKG)_WEBSITE  := https://github.com/kthohr/gcem
$(PKG)_DESCR    := GCEM
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 012ae73
$(PKG)_CHECKSUM := 05337e85ff2c662d2b7ca8521d80cbfc72786bfcc8d079de07ad389934f6cc7c
$(PKG)_GH_CONF  := kthohr/gcem/branches/master
$(PKG)_DEPS     :=
$(PKG)_TYPE     := source-only

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && $(TARGET)-cmake '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install
endef
