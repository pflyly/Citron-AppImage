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
./gradlew assembleRelease --console=plain --info --build-cache --scan --warning-mode=none
./gradlew bundleRelease

if [ ! -z "${ANDROID_KEYSTORE_B64}" ]; then
    rm "${ANDROID_KEYSTORE_FILE}"
fi

mkdir -p artifacts
mv app/build/outputs/apk/release/app-release.apk "artifacts/$APK_NAME.apk"
