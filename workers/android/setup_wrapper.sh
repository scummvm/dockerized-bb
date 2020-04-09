#! /bin/sh

# Create all directories
mkdir -p "${ANDROID_SDK_ROOT}" "${ANDROID_SDK_HOME}" "${GRADLE_USER_HOME}"

# Copy accepted licenses as we can't accept them during the build process
cp -R "${RO_ANDROID_ROOT}"/sdk/licenses "${ANDROID_SDK_ROOT}"/licenses

# Disable gradle build daemon as we kill the container after the build
echo "org.gradle.daemon=false" > "${GRADLE_USER_HOME}"/gradle.properties

# Don't do anything after so replace our process
exec "$@"
