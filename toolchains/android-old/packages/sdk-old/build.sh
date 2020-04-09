#! /bin/sh
SDK_VERSION=25.2.5
SDK_SHA1=72df3aa1988c0a9003ccdfd7a13a7b8bd0f47fc1

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..

# Don't load functions-platform.sh as it's not needed
NO_FUNCTIONS_PLATFORM=yes

. $HELPERS_DIR/functions.sh

do_make_bdir

export ANDROID_SDK_HOME=$(pwd)

do_http_fetch tools "https://dl.google.com/android/repository/tools_r${SDK_VERSION}-${HOST_TAG%-*}.zip" 'unzip' \
	"sha1:${SDK_SHA1}"

# Fix permissions
find . -type f -executable -exec chmod +x {} +

# Debian comes with OpenJDK 11 and SDK was designed for OpenJDK 8
# Between these two version, OpenJDK lost Java EE packages which are used by SDK
# Download interesting parts from Maven and fix loading

mkdir jaxb_libs

jaxb_wget () { wget --no-hsts --progress=dot "$1" -O "jaxb_libs/$(basename $1)"; }
jaxb_wget 'https://repo1.maven.org/maven2/javax/activation/activation/1.1.1/activation-1.1.1.jar'
jaxb_wget 'https://repo1.maven.org/maven2/org/glassfish/jaxb/jaxb-xjc/2.3.2/jaxb-xjc-2.3.2.jar'
jaxb_wget 'https://repo1.maven.org/maven2/org/glassfish/jaxb/jaxb-core/2.3.0.1/jaxb-core-2.3.0.1.jar'
jaxb_wget 'https://repo1.maven.org/maven2/org/glassfish/jaxb/jaxb-jxc/2.3.2/jaxb-jxc-2.3.2.jar'
jaxb_wget 'https://repo1.maven.org/maven2/javax/xml/bind/jaxb-api/2.3.1/jaxb-api-2.3.1.jar'
jaxb_wget 'https://repo1.maven.org/maven2/com/sun/xml/bind/jaxb-impl/2.3.2/jaxb-impl-2.3.2.jar'
jaxb_wget 'https://repo1.maven.org/maven2/com/sun/istack/istack-commons-runtime/3.0.8/istack-commons-runtime-3.0.8.jar'

for f in ./bin/sdkmanager; do
	sed -ie '/^CLASSPATH=/r /dev/stdin' $f <<'EOF'
CLASSPATH=$CLASSPATH:$APP_HOME/jaxb_libs/activation-1.1.1.jar:$APP_HOME/jaxb_libs/jaxb-xjc-2.3.2.jar:$APP_HOME/jaxb_libs/jaxb-core-2.3.0.1.jar:$APP_HOME/jaxb_libs/jaxb-jxc-2.3.2.jar:$APP_HOME/jaxb_libs/jaxb-api-2.3.1.jar:$APP_HOME/jaxb_libs/jaxb-impl-2.3.2.jar:$APP_HOME/jaxb_libs/istack-commons-runtime-3.0.8.jar
EOF
done

# The Debian we use don't support Java target 1.5 anymore (OpenJDK 11 is too recent), patch it to use 1.6
sed -ie 's#<property name="java.\(target\|source\)" value="1.5" />#<property name="java.\1" value="1.6" />#' ./ant/build.xml

# OpenJDK 11 doesn't have sun.misc.Base64Encoder anymore, provide it and patch sdklibs.jar
cp $PACKAGE_DIR/sun_misc_base64.jar ./lib/

# Install JDK and remove it just after to make final image lighter
# Do it like we do in Dockerfiles
apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		default-jdk-headless && \
	rm -rf /var/lib/apt/lists/*

# Spawn a subshell to not alter working directory
(DIR=$(pwd) && \
	cd .. && \
	jar xf "$DIR/lib/sdklib.jar" META-INF/MANIFEST.MF && \
	sed -i -e 's/^Class-Path: /Class-Path: sun_misc_base64.jar /' -e '/^Manifest-Version:/d' META-INF/MANIFEST.MF && \
	jar ufm "$DIR/lib/sdklib.jar" META-INF/MANIFEST.MF && \
	rm -rf META-INF)

DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y \
		default-jdk-headless

mkdir -p "${ANDROID_SDK_ROOT}"

# Download needed parts
yes | ./bin/sdkmanager --sdk_root="${ANDROID_SDK_ROOT}" "build-tools;25.0.3" platform-tools "platforms;android-28"

# Cleanup what we don't need in tools
rm -rf apps lib/monitor-x86 lib/monitor-x86_64 qemu emulator* bin64 lib64 emulator64-crash-service

# Move
mkdir "${ANDROID_SDK_ROOT}/tools/"
mv ./* "${ANDROID_SDK_ROOT}/tools/"

do_clean_bdir
