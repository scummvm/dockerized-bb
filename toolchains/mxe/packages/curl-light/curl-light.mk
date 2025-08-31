# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := curl-light
$(PKG)_WEBSITE  := https://curl.haxx.se/libcurl/
$(PKG)_DESCR    := cURL (without deps or IDN)
$(PKG)_IGNORE   = $(curl_IGNORE)
$(PKG)_VERSION  = $(curl_VERSION)
$(PKG)_CHECKSUM = $(curl_CHECKSUM)
$(PKG)_SUBDIR   = $(curl_SUBDIR)
$(PKG)_FILE     = $(curl_FILE)
$(PKG)_URL      = $(curl_URL)
$(PKG)_DEPS     := cc

# Use test file provided by MXE
$(PKG)_TEST_FILE = $(curl_TEST_FILE)

define $(PKG)_UPDATE
    echo $(curl_VERSION)
endef

define $(PKG)_BUILD
    cd '$(SOURCE_DIR)' && autoreconf -fi
    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --with-schannel \
        --without-winidn \
        --without-libpsl \
        --enable-sspi \
        --enable-ipv6 \
        --enable-threaded-resolver \
        --disable-pthreads
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(MXE_DISABLE_DOCS)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install $(MXE_DISABLE_DOCS)
    ln -sf '$(PREFIX)/$(TARGET)/bin/curl-config' '$(PREFIX)/bin/$(TARGET)-curl-config'

    '$(TARGET)-gcc' \
        -W -Wall -Werror -ansi -pedantic \
        '$(TEST_FILE)' -o '$(PREFIX)/$(TARGET)/bin/test-curl.exe' \
        `'$(TARGET)-pkg-config' libcurl --cflags --libs`
endef
