# Patch pe-util to not build target binary but still install wrapper scripts for native one
# newline variable is defined by MXE
PKG             := pe-util
$(PKG)_DEPS     := $(BUILD)~$(PKG)

define $(PKG)_BUILD
	(echo '#!/bin/sh'; \
	echo 'exec "$(PREFIX)/$(BUILD)/bin/peldd" \
		--clear-path \
		--path "$(PREFIX)/$(TARGET)/bin" \
		--wlist uxtheme.dll \
		--wlist opengl32.dll \
		--wlist userenv.dll \
		"$$@"') \
                 > '$(PREFIX)/bin/$(TARGET)-peldd'
        chmod 0755 '$(PREFIX)/bin/$(TARGET)-peldd'
endef
