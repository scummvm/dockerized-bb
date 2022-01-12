PKG             := lld
$(PKG)_WEBSITE  := https://lld.llvm.org
$(PKG)_DESCR    := LLD Linker
$(PKG)_VERSION  := system

define $(PKG)_BUILD
    ln -s /usr/bin/ld.lld '$(MXE_PREFIX_DIR)/bin/$(TARGET)-ld.lld'
endef
