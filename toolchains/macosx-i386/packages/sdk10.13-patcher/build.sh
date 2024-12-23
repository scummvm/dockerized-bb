#! /bin/sh

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

# libcurl provided in SDK 10.13 is too recent for MacOS 10.6 system libcurl
# Patch the header and the stub to make sure it will work

# First, make apps believe they compile against the original libcurl version
sed -i -f - "${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/include/curl/curlver.h" <<'EOF'
s/LIBCURL_VERSION .*/LIBCURL_VERSION "7.19.7"/
s/LIBCURL_VERSION_MINOR .*/LIBCURL_VERSION_MINOR 19/
s/LIBCURL_VERSION_PATCH .*/LIBCURL_VERSION_PATCH 7/
s/LIBCURL_VERSION_NUM .*/LIBCURL_VERSION_NUM 0x071307/
s/LIBCURL_TIMESTAMP .*/LIBCURL_TIMESTAMP "Wed Nov  4 12:34:59 UTC 2009"/
EOF

# Then, copy the proper stub (generated using tapi from MacOS 10.6 libcurl.4.dylib)
cp "${PACKAGE_DIR}/libcurl.4.tbd" "${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/lib/libcurl.4.tbd"

# libedit provided in SDK 10.13 is too recent for MacOS 10.6 system libedit
# Patch the headers and the stub to make sure it will work

sed -i -f - "${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/include/histedit.h" <<'EOF'
/_el_fn_sh_complete/d
/EL_R\?PROMPT_ESC/d
/EL_RESIZE/d
/Begin Wide Character Support/{N;a\
#if 0
}
/tok_wstr/{N;a\
#endif
}
EOF

sed -i -f - "${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/include/editline/readline.h" <<'EOF'
/RL_PROMPT_/d
/rl_completion_word_break_hook/d
/rl_set_prompt/d
/rl_on_new_line/d
EOF

# Then, copy the proper stub (generated using tapi from MacOS 10.6 libedit.2.dylib) and switch to version 2 instead of 3
rm "${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/lib/libedit.2.tbd" \
	"${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/lib/libedit.tbd" \
	"${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/lib/libreadline.tbd"
cp "${PACKAGE_DIR}/libedit.2.tbd" "${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/lib/libedit.2.tbd"
ln -s "libedit.2.tbd" "${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/lib/libedit.tbd"
ln -s "libedit.2.tbd" "${TARGET_DIR}/SDK/MacOSX10.13.sdk/usr/lib/libreadline.tbd"
