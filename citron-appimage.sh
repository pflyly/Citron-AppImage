#!/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

REPO="https://git.citron-emu.org/Citron/Citron.git"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

if [ "$ARCH" = 'x86_64' ]; then
	if [ "$1" = 'v3' ]; then
		echo "Making optimized build of citron for Steamdeck"
		ARCH_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto"
	fi
fi

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD CITRON, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron; then
	echo "Using mirror instead..."
	rm -rf ./citron || true
	git clone 'https://github.com/pkgforge-community/git.citron-emu.org-Citron-Citron.git' ./citron
fi

cd ./citron
if [ "$DEVEL" = 'true' ]; then
    COMM_COUNT="$(git rev-list --count HEAD)"
    COMM_HASH="$(git rev-parse --short HEAD)"
    BUILD_DATE="$(date +"%Y%m%d")"
    echo "Making nightly build"
    VERSION="nightly"
    COUNT="${COMM_COUNT}"
    HASH="${COMM_HASH}"
    DATE="${BUILD_DATE}"
else
    CITRON_TAG=$(git describe --tags)
    BUILD_DATE="$(date +"%Y%m%d")"
    echo "Making stable \"$CITRON_TAG\" build"
    git checkout "$CITRON_TAG"
    COMM_COUNT="$(git rev-list --count HEAD)"
    COMM_HASH="$(git rev-parse --short HEAD)"
    VERSION="$(echo "$CITRON_TAG" | awk -F'-' '{print $1}')"
    COUNT="${COMM_COUNT}"
    HASH="${COMM_HASH}"
    DATE="${BUILD_DATE}"
fi
git submodule update --init --recursive -j$(nproc)

#Replaces 'boost::asio::io_service' with 'boost::asio::io_context' for compatibility with Boost.ASIO versions 1.74.0 and later
find src -type f -name '*.cpp' -exec sed -i 's/boost::asio::io_service/boost::asio::io_context/g' {} \;

mkdir build
cd build
cmake .. -GNinja \
	-DCITRON_USE_BUNDLED_VCPKG=OFF \
	-DCITRON_USE_BUNDLED_QT=ON \
	-DUSE_SYSTEM_QT=OFF \
	-DCITRON_USE_BUNDLED_FFMPEG=OFF \
	-DCITRON_TESTS=OFF \
	-DCITRON_CHECK_SUBMODULES=OFF \
	-DCITRON_USE_LLVM_DEMANGLE=OFF \
        -DCITRON_USE_BUNDLED_SDL2=ON \
 	-DCITRON_USE_EXTERNAL_SDL2=OFF \
	-DCITRON_ENABLE_LTO=ON \
        -DCITRON_USE_QT_MULTIMEDIA=ON \
	-DCITRON_USE_QT_WEB_ENGINE=OFF \
	-DENABLE_QT_TRANSLATION=ON \
	-DUSE_DISCORD_PRESENCE=OFF \
	-DBUNDLE_SPEEX=ON \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error" \
	-DCMAKE_C_FLAGS="$ARCH_FLAGS" \
	-DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
	-DCMAKE_BUILD_TYPE=Release
ninja
sudo ninja install
echo "$VERSION" >~/version
echo "$COUNT" >~/count
echo "$HASH" >~/hash
echo "$DATE" >~/date
VERSION="$(cat ~/version)"
COUNT="$(cat ~/count)"
HASH="$(cat ~/hash)"
DATE="$(cat ~/date)"

# Make appimage using citron appimage-builder.sh, we only need it to generate the appdir
cd.. && ./appimage-builder.sh citron ./Citron/build
cd ./Citron/build/deploy-linux
rm -rf ./Citron/build/deploy-linux/citron*.AppImage # Delete the generated appimage, cause it's useless now
cp /usr/lib/libSDL3.so* ./Citron/build/deploy-linux/AppDir/usr/lib/ # Copying libsdl3 to the already done appdir

# Turn appdir into appimage
cd ./Citron/build/deploy-linux/
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
	--compression zstd:level=22 -S24 -B16 \
	--header uruntime \
	-i ./AppDir -o Citron-"$VERSION"-"${DATE}"-"${COUNT}"-"${HASH}"-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
mv *.AppImage* ..
echo "All Done!"
