#!/bin/bash -ex

git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron

if [ ! -z "${ANDROID_KEYSTORE_B64}" ]; then
    export ANDROID_KEYSTORE_FILE="${GITHUB_WORKSPACE}/ks.jks"
    base64 --decode <<< "${ANDROID_KEYSTORE_B64}" > "${ANDROID_KEYSTORE_FILE}"
fi

cd ./citron
git submodule update --init --recursive
find src -type f -name 'build.gradle.kts' -exec sed -i 's/"4\.0\.1"/"3.31.6"/g' {} +
COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
APK_NAME="Citron-nightly-${DATE}-${COUNT}-${HASH}-android-universal"

cd src/android
chmod +x ./gradlew
./gradlew assembleRelease --console=plain --info

if [ ! -z "${ANDROID_KEYSTORE_B64}" ]; then
    rm "${ANDROID_KEYSTORE_FILE}"
fi
APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
if [ -z "$APK_PATH" ]; then
    echo "Error: APK not found in expected directory."
    exit 1
fi
mkdir -p artifacts
mv "$APK_PATH" "artifacts/$APK_NAME.apk"
