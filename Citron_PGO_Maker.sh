#!/bin/bash

# Steam Deck Citron PGO Optimized building script, originally from the Citron wiki and memberes of discord

# Install dependencies

sudo pacman -Syu --needed base-devel boost catch2 cmake ffmpeg fmt git glslang libzip lz4 mbedtls ninja nlohmann-json openssl opus qt5 sdl2 zlib zstd zip unzip qt6-base qt6-tools qt6-svg qt6-declarative qt6-webengine sdl3 qt6-multimedia clang qt6-wayland fuse2 rapidjson

# Clone from Citron website

git clone --recursive https://git.citron-emu.org/Citron/Citron.git
cd Citron

# If already cloned the repo once, only need to update the clone to the latest including submodules

git pull
git submodule update --init --recursive

# Start to build PGO instrument
mkdir build
cd $HOME/Citron/build
cmake .. -GNinja -DCITRON_USE_BUNDLED_VCPKG=ON -DCITRON_TESTS=OFF -DCITRON_ENABLE_LTO=ON -DCITRON_ENABLE_PGO_INSTRUMENT=ON -DENABLE_QT_TRANSLATION=ON -DCITRON_USE_LLVM_DEMANGLE=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto -Wno-error" -DCMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto" -DUSE_DISCORD_PRESENCE=OFF -DBUNDLE_SPEEX=ON -DCMAKE_SYSTEM_PROCESSOR=x86_64 -DCMAKE_BUILD_TYPE=Release
ninja
# Run the instrument build in the /build/bin folder wih as many titles as you can to generate engough profiles

# Start to build PGO optimized after running the PGO instrument build for several times
cd $HOME/Citron/build
cmake .. -GNinja -DCITRON_USE_BUNDLED_VCPKG=ON -DCITRON_TESTS=OFF -DCITRON_ENABLE_LTO=ON -DCITRON_ENABLE_PGO_INSTRUMENT=OFF -DCITRON_ENABLE_PGO_OPTIMIZE=ON -DENABLE_QT_TRANSLATION=ON -DCITRON_USE_LLVM_DEMANGLE=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto -fprofile-correction -Wno-error" -DCMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto" -DUSE_DISCORD_PRESENCE=OFF -DBUNDLE_SPEEX=ON -DCMAKE_SYSTEM_PROCESSOR=x86_64 -DCMAKE_BUILD_TYPE=Release
ninja

# Zip the outcome binaries, rename and move the final zip to back up place
cd $HOME/Citron/build/bin
zip -r citron.zip ./
LATEST_ZIP=$(ls -1t citron*.zip | head -n 1) # find the most recent zip
COMM_COUNT="$(git rev-list --count HEAD)"
COMM_HASH="$(git rev-parse --short=9 HEAD)"
BUILD_DATE=$(date +"%Y%m%d")
ZIP_NAME="citron-nightly-${BUILD_DATE}-${COMM_COUNT}-${COMM_HASH}-x86_64-PGO-Optimized.zip"
sudo mv -v -f "${LATEST_ZIP}" "${ZIP_NAME}"
FILESIZE=$(du -h ${ZIP_NAME}  | awk '{ print $1 }')
SHA256SUM=$(sha256sum "./${ZIP_NAME}" | awk '{ print $1 }')
echo -e "\033[31m${ZIP_NAME}\033[0m has been moved to \033[32m$HOME/Downloads/\033[0m"
echo -e "File Size=\033[31m${FILESIZE}\033[0m | SHA256SUM=\033[31m${SHA256SUM}\033[0m"
sudo mv -f $HOME/Citron/build/bin/citron*.zip $HOME/Downloads/

# Create appimage using Citron appimage-builder script
cd $HOME/Citron
sudo $HOME/Citron/appimage-builder.sh citron $HOME/Citron/build
cd $HOME/Citron/build/deploy-linux
sudo rm -rf $HOME/Citron/build/deploy-linux/citron*.AppImage # Delete the generated appimage, cause it's useless
sudo cp /usr/lib/libSDL3.so* $HOME/Citron/build/deploy-linux/AppDir/usr/lib/ # Copying libsdl3 to the already done appdir
sudo wget https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-x86_64.AppImage
sudo chmod +x $HOME/Citron/build/deploy-linux/appimagetool-x86_64.AppImage
sudo ./appimagetool-x86_64.AppImage $HOME/Citron/build/deploy-linux/AppDir

# Rename and move the final Appimage to back up place
LATEST_APPIMAGE=$(ls -1t citron*.AppImage | head -n 1) # find the most recent AppImage
COMM_COUNT="$(git rev-list --count HEAD)"
COMM_HASH="$(git rev-parse --short=9 HEAD)"
BUILD_DATE=$(date +"%Y%m%d")
APPIMAGE_NAME="citron-nightly-${BUILD_DATE}-${COMM_COUNT}-${COMM_HASH}-x86_64-PGO-Optimized.AppImage"
sudo mv -v -f "${LATEST_APPIMAGE}" "${APPIMAGE_NAME}"
FILESIZE=$(du -h ${APPIMAGE_NAME} | awk '{ print $1 }')
SHA256SUM=$(sha256sum "./${APPIMAGE_NAME}" | awk '{ print $1 }')
echo -e "\033[31m${APPIMAGE_NAME}\033[0m has been moved to \033[32m$HOME/Downloads/\033[0m"
echo -e "File Size=\033[31m${FILESIZE}\033[0m | SHA256SUM=\033[31m${SHA256SUM}\033[0m"
sudo mv -f $HOME/Citron/build/deploy-linux/citron*.AppImage $HOME/Downloads/

# Delete the build folder for building cleanly next time
cd $HOME/Citron
sudo rm -rf $HOME/Citron/build

