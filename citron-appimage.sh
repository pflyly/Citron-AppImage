#!/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

REPO="https://git.citron-emu.org/Citron/Citron.git"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
ARCH_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD CITRON, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron; then
	echo "Using mirror instead..."
	rm -rf ./citron || true
	git clone 'https://github.com/pkgforge-community/git.citron-emu.org-Citron-Citron.git' ./citron
fi

cd ./citron
COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
echo "Making nightly build"

git submodule update --init --recursive -j$(nproc)

#Replaces 'boost::asio::io_service' with 'boost::asio::io_context' for compatibility with Boost.ASIO versions 1.74.0 and later
find src -type f -name '*.cpp' -exec sed -i 's/boost::asio::io_service/boost::asio::io_context/g' {} \;

mkdir build
cd build
cmake .. -GNinja \
	-DCITRON_USE_BUNDLED_VCPKG=OFF \
	-DCITRON_USE_BUNDLED_QT=OFF \
 	-DUSE_SYSTEM_QT=ON \
	-DCITRON_TESTS=OFF \
	-DCITRON_CHECK_SUBMODULES=OFF \
	-DCITRON_USE_LLVM_DEMANGLE=OFF \
        -DCITRON_USE_BUNDLED_SDL2=ON \
 	-DCITRON_USE_EXTERNAL_SDL2=OFF \
	-DCITRON_ENABLE_LTO=ON \
	-DENABLE_QT_TRANSLATION=ON \
	-DUSE_DISCORD_PRESENCE=OFF \
	-DBUNDLE_SPEEX=ON \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error" \
	-DCMAKE_C_FLAGS="$ARCH_FLAGS" \
	-DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
	-DCMAKE_BUILD_TYPE=Release
ninja
sudo ninja install
echo "$HASH" >~/hash

# Make appimage using citron appimage-builder.sh, we only need it to generate the appdir
cd ..
chmod +x ./appimage-builder.sh
./appimage-builder.sh citron ./build
rm -rf ./build/deploy-linux/citron*.AppImage # Delete the generated appimage, cause it's useless now
cp /usr/lib/libSDL3.so* ./build/deploy-linux/AppDir/usr/lib/ # Copying libsdl3 to the already done appdir

# Turn appdir into appimage
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B32 \
	--header uruntime \
	-i ./citron/build/deploy-linux/AppDir -o Citron-nightly-"${DATE}"-"${COUNT}"-"${HASH}"-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

echo "All Done!"
